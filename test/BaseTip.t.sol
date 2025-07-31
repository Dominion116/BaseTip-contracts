// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BaseTip} from "../src/BaseTip.sol";

contract BaseTipTest is Test {
    BaseTip public baseTip;
    address public creator = makeAddr("creator");
    address public tipper = makeAddr("tipper");
    string public contentId = "https://example.com/article1";
    
    function setUp() public {
        baseTip = new BaseTip();
        
        // Give test accounts some ETH
        vm.deal(creator, 10 ether);
        vm.deal(tipper, 10 ether);
    }
    
    function testRegisterContent() public {
        vm.prank(creator);
        baseTip.registerContent(contentId);
        
        (address contentCreator, uint256 totalTips, uint256 tipCount) = 
            baseTip.getContent(contentId);
            
        assertEq(contentCreator, creator);
        assertEq(totalTips, 0);
        assertEq(tipCount, 0);
        assertTrue(baseTip.contentExists(contentId));
    }
    
    function testTipContent() public {
        // Register content
        vm.prank(creator);
        baseTip.registerContent(contentId);
        
        // Send tip
        uint256 tipAmount = 0.01 ether;
        vm.prank(tipper);
        baseTip.tipContent{value: tipAmount}(contentId);
        
        // Check results
        (,uint256 totalTips, uint256 tipCount) = baseTip.getContent(contentId);
        uint256 expectedCreatorAmount = tipAmount - (tipAmount * 100 / 10000); // Minus 1% fee
        
        assertEq(totalTips, expectedCreatorAmount);
        assertEq(tipCount, 1);
        assertEq(baseTip.creatorEarnings(creator), expectedCreatorAmount);
    }
    
    function testWithdrawEarnings() public {
        // Setup: register and tip
        vm.prank(creator);
        baseTip.registerContent(contentId);
        
        uint256 tipAmount = 0.01 ether;
        vm.prank(tipper);
        baseTip.tipContent{value: tipAmount}(contentId);
        
        // Check balance before withdrawal
        uint256 creatorBalanceBefore = creator.balance;
        uint256 expectedEarnings = baseTip.creatorEarnings(creator);
        
        // Withdraw
        vm.prank(creator);
        baseTip.withdrawEarnings();
        
        // Check results
        assertEq(creator.balance, creatorBalanceBefore + expectedEarnings);
        assertEq(baseTip.creatorEarnings(creator), 0);
    }
    
    function testCannotTipOwnContent() public {
        vm.prank(creator);
        baseTip.registerContent(contentId);
        
        vm.prank(creator);
        vm.expectRevert("Cannot tip your own content");
        baseTip.tipContent{value: 0.01 ether}(contentId);
    }
    
    function testMinimumTipAmount() public {
        vm.prank(creator);
        baseTip.registerContent(contentId);
        
        vm.prank(tipper);
        vm.expectRevert("Tip below minimum amount");
        baseTip.tipContent{value: 0.0001 ether}(contentId);
    }
}
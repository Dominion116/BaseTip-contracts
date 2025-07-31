// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title BaseTip
 * @dev Micro-donations platform for content creators on Base
 */
contract BaseTip is ReentrancyGuard, Ownable {
    
    // Minimum tip amount (0.001 ETH = ~$1-3 depending on ETH price)
    uint256 public constant MINIMUM_TIP = 0.001 ether;
    
    // Platform fee (1% = 100 basis points)
    uint256 public platformFee = 100; // 1%
    uint256 public constant MAX_PLATFORM_FEE = 500; // 5% max
    uint256 public constant BASIS_POINTS = 10000;
    
    // Content struct
    struct Content {
        address creator;
        string contentId; // URL or unique identifier
        uint256 totalTips;
        uint256 tipCount;
        bool exists;
    }
    
    // Storage
    mapping(string => Content) public contents;
    mapping(address => uint256) public creatorEarnings;
    mapping(address => string[]) public creatorContent;
    uint256 public totalPlatformFees;
    
    // Events
    event ContentRegistered(string indexed contentId, address indexed creator);
    event TipSent(
        string indexed contentId, 
        address indexed tipper, 
        address indexed creator,
        uint256 amount,
        uint256 platformFee
    );
    event EarningsWithdrawn(address indexed creator, uint256 amount);
    event PlatformFeesWithdrawn(uint256 amount);
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Register content for receiving tips
     * @param contentId Unique identifier for the content (URL, hash, etc.)
     */
    function registerContent(string calldata contentId) external {
        require(bytes(contentId).length > 0, "Content ID cannot be empty");
        require(!contents[contentId].exists, "Content already registered");
        
        contents[contentId] = Content({
            creator: msg.sender,
            contentId: contentId,
            totalTips: 0,
            tipCount: 0,
            exists: true
        });
        
        creatorContent[msg.sender].push(contentId);
        
        emit ContentRegistered(contentId, msg.sender);
    }
    
    /**
     * @dev Send a tip to content creator
     * @param contentId The content to tip
     */
    function tipContent(string calldata contentId) external payable nonReentrant {
        require(msg.value >= MINIMUM_TIP, "Tip below minimum amount");
        require(contents[contentId].exists, "Content not found");
        
        Content storage content = contents[contentId];
        require(content.creator != msg.sender, "Cannot tip your own content");
        
        // Calculate platform fee
        uint256 fee = (msg.value * platformFee) / BASIS_POINTS;
        uint256 creatorAmount = msg.value - fee;
        
        // Update storage
        content.totalTips += creatorAmount;
        content.tipCount += 1;
        creatorEarnings[content.creator] += creatorAmount;
        totalPlatformFees += fee;
        
        emit TipSent(contentId, msg.sender, content.creator, creatorAmount, fee);
    }
    
    /**
     * @dev Withdraw accumulated earnings
     */
    function withdrawEarnings() external nonReentrant {
        uint256 amount = creatorEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");
        
        creatorEarnings[msg.sender] = 0;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit EarningsWithdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Get content information
     * @param contentId The content to query
     */
    function getContent(string calldata contentId) external view returns (
        address creator,
        uint256 totalTips,
        uint256 tipCount
    ) {
        require(contents[contentId].exists, "Content not found");
        Content memory content = contents[contentId];
        return (content.creator, content.totalTips, content.tipCount);
    }
    
    /**
     * @dev Get creator's content list
     * @param creator The creator address
     */
    function getCreatorContent(address creator) external view returns (string[] memory) {
        return creatorContent[creator];
    }
    
    /**
     * @dev Check if content exists
     * @param contentId The content to check
     */
    function contentExists(string calldata contentId) external view returns (bool) {
        return contents[contentId].exists;
    }
    
    // Admin functions
    
    /**
     * @dev Update platform fee (only owner)
     * @param newFee New fee in basis points
     */
    function updatePlatformFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_PLATFORM_FEE, "Fee too high");
        uint256 oldFee = platformFee;
        platformFee = newFee;
        emit PlatformFeeUpdated(oldFee, newFee);
    }
    
    /**
     * @dev Withdraw platform fees (only owner)
     */
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 amount = totalPlatformFees;
        require(amount > 0, "No fees to withdraw");
        
        totalPlatformFees = 0;
        
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit PlatformFeesWithdrawn(amount);
    }
}
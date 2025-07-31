// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBaseTip {
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
    
    // Core functions
    function registerContent(string calldata contentId) external;
    function tipContent(string calldata contentId) external payable;
    function withdrawEarnings() external;
    
    // View functions
    function getContent(string calldata contentId) external view returns (
        address creator,
        uint256 totalTips,
        uint256 tipCount
    );
    function getCreatorContent(address creator) external view returns (string[] memory);
    function contentExists(string calldata contentId) external view returns (bool);
    function creatorEarnings(address creator) external view returns (uint256);
}
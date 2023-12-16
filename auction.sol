// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Auction {
    address public owner;
    uint256 public auctionEndTime;
    uint256 public highestBindingBid;
    uint256 public minBidIncrement;
    address public highestBidder;
    address[] public bidders;

    mapping(address => uint256) public bids;

    constructor(uint256 durationMinutes, uint256 _minBidIncrement) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + (durationMinutes * 1 minutes);
        minBidIncrement = _minBidIncrement;
    }

    function placeBid() external payable {
        require(block.timestamp <= auctionEndTime, "Auction has ended");
        require(msg.value >= highestBindingBid + minBidIncrement, "Bid must be at least minBidIncrement higher");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBindingBid;
        } else {
            bidders.push(msg.sender);
        }

        highestBindingBid = msg.value;
        highestBidder = msg.sender;
        bids[msg.sender] += msg.value;
    }

    function finalizeAuction() external {
        require(msg.sender == owner, "Only the owner can finalize the auction");
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet");

        payable(owner).transfer(highestBindingBid);
    }

    function cancelAuction() external {
        require(msg.sender == owner, "Only the owner can cancel the auction");
        require(block.timestamp < auctionEndTime, "Auction has already ended");

        for (uint256 i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];
            uint256 amount = bids[bidder];
            bids[bidder] = 0;
            payable(bidder).transfer(amount);
        }

        auctionEndTime = block.timestamp; // Cancel the auction immediately
    }

    function withdraw() external {
        require(block.timestamp >= auctionEndTime, "Auction has not ended yet");
        require(msg.sender != highestBidder, "The highest bidder cannot withdraw");

        uint256 amount = bids[msg.sender];
        require(amount > 0, "No funds to withdraw");

        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}

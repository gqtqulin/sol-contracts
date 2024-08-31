// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnglishAuction {
    string public item;
    address payable public immutable seller;
    uint256 public endAt;
    bool public started;
    bool public ended;
    uint256 public highestBid;
    address public highestBidder;
    mapping(address => uint256) public bids;

    event Start(string item, uint256 startBid);
    event Bid(address bidder, uint256 bid);
    event End(address bidder, uint256 bid);
    event Withdraw(address sender, uint256 amount);

    constructor(string memory _item, uint256 _startBid) {
        item = _item;
        highestBid = _startBid;
        seller = payable(msg.sender);
    }

    modifier onlySeller() {
        require(msg.sender == seller, "not a seller");
        _;
    }

    modifier hasStarted() {
        require(started, "has not started yet");
        _;
    }

    modifier notEnded() {
        // require(block.timestamp < endAt, "has ended");
        require(!ended, "has ended");
        _;
    }

    function start() external onlySeller() {
        require(!started, "already started");
        started = true;
        endAt = block.timestamp + 70;
        emit Start(item, highestBid);
    }

    function bid() external payable hasStarted() notEnded() {
        require(msg.value > highestBid, "too low");
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }
        highestBid = msg.value;
        highestBidder = msg.sender;
        emit Bid(msg.sender, msg.value);
    }

    function end() external hasStarted() {
        require(!ended, "already ended");
        require(block.timestamp >= endAt, "cat't stop auction yet");
        ended = true;
        if (highestBidder != address(0)) {
            seller.transfer(highestBid);
        }
        emit End(highestBidder, highestBid);
    }

    function withdraw() external {
        uint256 refundAmount = bids[msg.sender];
        require(refundAmount > 0, "incorrect amout");
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
        emit Withdraw(msg.sender, refundAmount);
    }

}
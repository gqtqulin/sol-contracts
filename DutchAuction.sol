// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DutchAuction {
    uint private constant DURATION = 1 days;
    address payable public immutable seller;
    uint256 public immutable startingPrice;
    uint256 public immutable startsAt;
    uint256 public immutable endsAt;
    uint256 public immutable discountRate;
    string public item;
    bool public isStopped;

    constructor(
        uint256 _startPrice,
        uint256 _discountRate,
        string memory _item
    ) {
        seller = payable(msg.sender);
        startingPrice = _startPrice;
        discountRate = _discountRate;
        startsAt = block.timestamp;
        endsAt = block.timestamp + DURATION;

        require(
            startingPrice >= _discountRate * DURATION,
            "starting price and discount rate is incorrect"
        );

        item = _item;
    }

    modifier notStopped() {
        require(!isStopped, "auction is stopped");
        _;
    }

    function getPrice() public view notStopped() returns (uint256) {
        uint256 timeElapsed = block.timestamp - startsAt;
        uint256 discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function buy() external payable notStopped() {
        require(block.timestamp < endsAt, "auction ended");
        uint256 price = getPrice();
        require(msg.value >= price, "amount is not enough");

        uint256 refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        seller.transfer(address(this).balance);
        isStopped = true;
    }

}

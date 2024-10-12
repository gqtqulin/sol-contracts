// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/interfaces/IERC20.sol";

contract Crowdfunding {
    struct Company {
        address owner;
        uint goal;
        uint pledged;
        uint startAt;
        uint endAt;
        bool claimed;
    }

    IERC20 public immutable token;

    mapping(uint => mapping(address => uint)) pledges;
    mapping(uint => Company) public companies;

    uint public currentId;

    uint public constant MAX_DURATION = 100 days;
    uint public constant MIN_DURATION = 10;

    event Launched(uint id, address owner, uint goal, uint startAt, uint endAt);
    event Unpledged(uint id, address pledger, uint amount);
    event Refunded(uint id, address pledget, uint amount);
    event Pledged(uint id, address pledger, uint amount);
    event Canceled(uint id);
    event Claimed(uint id);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(uint _goal, uint _startAt, uint _endAt) external {
        require(_startAt >= block.timestamp, "incorrect start at");
        require(_endAt >= _startAt + MIN_DURATION, "incorrect end at");
        require(_endAt <= _startAt + MAX_DURATION, "too long");
        
        companies[currentId] = Company({
            owner: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launched(
            currentId,
            msg.sender,
            _goal,
            _startAt,
            _endAt
        );

        currentId++;
    }

    function cancel(uint _id) external {
        Company memory company = companies[_id];
        require(msg.sender == company.owner, "not an owner");
        require(block.timestamp < company.startAt, "already started");

        delete companies[_id];
        emit Canceled(_id);
    }

    function pledge(uint _id, uint _amount) external {
        Company storage company = companies[_id];
        require(block.timestamp >= company.startAt, "not started");
        require(block.timestamp < company.endAt, "ended");

        company.pledged += _amount;
        pledges[_id][msg.sender]  += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit Pledged(_id, msg.sender, _amount);
    }

    function unpledge(uint _id, uint _amount) external {
        Company storage company = companies[_id];
        require(block.timestamp < company.endAt, "ended");

        company.pledged -= _amount;
        pledges[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
        emit Unpledged(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        Company storage company = companies[_id];
        require(msg.sender == company.owner, "not an owner");
        require(block.timestamp > company.endAt, "not ended");
        require(company.pledged >= company.goal, "pledged is too low");
        require(!company.claimed, "already claimed");
        
        company.claimed = true;
        token.transfer(msg.sender, company.pledged);
        emit Claimed(_id);
    }

    function refund(uint _id) external {
        Company storage company = companies[_id];
        require(block.timestamp > company.endAt, "not ended");
        require(company.pledged < company.goal, "reached goal");

        uint pledgedAmount = pledges[_id][msg.sender];
        pledges[_id][msg.sender] = 0;
        token.transfer(msg.sender, pledgedAmount);
        emit Refunded(_id, msg.sender, pledgedAmount);
    }

    /**
        для ручного теста
        развернуть ERC20???
     */
    function getTestTime() public view returns (uint256, uint256) {
        return (block.timestamp, block.timestamp + 40);
    }
}
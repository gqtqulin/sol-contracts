// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/interfaces/IERC20.sol";

/**
    краудфандинг
    на erc20, хранит компании с пожертвованиями
    возможность закинуть в компанию, вывести
    забрать деньги при успехе комании и вернуть средства при неудаче
 */
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

    // id компании => (жертвователь => сумма)
    mapping(uint => mapping(address => uint)) pledges;
    mapping(uint => Company) public companies;

    // для инкремента id
    uint public currentId;

    uint public constant MAX_DURATION = 100 days;
    uint public constant MIN_DURATION = 10;

    event Launched(uint id, address owner, uint goal, uint startAt, uint endAt);
    event Unpledged(uint id, address pledger, uint amount);
    event Refunded(uint id, address pledger, uint amount);
    event Pledged(uint id, address pledger, uint amount);
    event Canceled(uint id);
    event Claimed(uint id);

    constructor(address _token) {
        token = IERC20(_token);
    }

    /**
        @notice запуск компании
        @param _goal цель сумма
        @param _startAt когда начинается
        @param _endAt когда заканчивается
     */
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

    /**
        @notice отмена компании по id
        @param _id id компании
     */
    function cancel(uint _id) external {
        Company memory company = companies[_id];
        require(msg.sender == company.owner, "not an owner");
        require(block.timestamp < company.startAt, "already started");

        delete companies[_id];
        emit Canceled(_id);
    }

    /**
        @notice пожертвовать компании по id
        для использования функции нужно сделать allowance
        на адрес этого контракта
        @param _id id компании
        @param _amount сумма
     */
    function pledge(uint _id, uint _amount) external {
        Company storage company = companies[_id];
        require(block.timestamp >= company.startAt, "not started");
        require(block.timestamp < company.endAt, "ended");

        company.pledged += _amount;
        pledges[_id][msg.sender]  += _amount;
        // перевести со счета sender'а на этот контракт
        token.transferFrom(msg.sender, address(this), _amount);
        emit Pledged(_id, msg.sender, _amount);
    }

    /**
        @notice вывести свои пожертвования (можно часть)
        по окончании компании (неудаче)
        @param _id id компании
        @param _amount сумма
     */
    function unpledge(uint _id, uint _amount) external {
        Company storage company = companies[_id];
        require(block.timestamp < company.endAt, "ended");

        company.pledged -= _amount;
        pledges[_id][msg.sender] -= _amount;
        // переведим со счета этого контракта на отправителя
        token.transfer(msg.sender, _amount);
        emit Unpledged(_id, msg.sender, _amount);
    }

    /**
        @notice вывести при удале компании средства
        только для владельца компании
        @param _id id компании
     */
    function claim(uint _id) external {
        Company storage company = companies[_id];
        require(msg.sender == company.owner, "not an owner");
        require(block.timestamp > company.endAt, "not ended");
        require(company.pledged >= company.goal, "pledged is too low");
        require(!company.claimed, "already claimed");
        
        company.claimed = true;
        // с текущего контракта отправителю транкзакции (владельцу компании)
        token.transfer(msg.sender, company.pledged);
        emit Claimed(_id);
    }

    /**
        @notice вывести средства жертвователем при
        неудачном окончании компании
     */
    function refund(uint _id) external {
        Company storage company = companies[_id];
        require(block.timestamp > company.endAt, "not ended");
        require(company.pledged < company.goal, "reached goal");

        uint pledgedAmount = pledges[_id][msg.sender];
        pledges[_id][msg.sender] = 0;
        // с текущего контракта отправителю
        token.transfer(msg.sender, pledgedAmount);
        emit Refunded(_id, msg.sender, pledgedAmount);
    }

    /**
        для теста
     */
    function getTestTime() public view returns (uint256, uint256) {
        uint256 current = block.timestamp;
        return (current + 20, current + 60);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// 15:40

contract Ownable {
    address[] public owners;
    mapping(address => bool) public isOwner;

    constructor(address[] memory _owners) {
        require(_owners.length > 0, "no owners");
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "zero address");
            require(!isOwner[owner], "not unique");
            
            owners.push(owner);
            isOwner[owner] = true;
        }
    }

    modifier onlyOwners() {
        require(isOwner[msg.sender], "not an owner");
        _;
    }

    // добавление овнеров ?

}

contract MultiSig is Ownable {
    uint public requiredApprovals;
    struct Transaction {
        address _to;
        uint _value;
        bytes _data;
        bool _executed;
    }
    Transaction[] public transactions;
    // index => amount approval
    mapping(uint => uint) public approvalsCount;
    mapping(uint => mapping(address => bool)) public approved;

    event Deposit(address _from, uint256 _amount);
    event Submit(uint256 _txId);
    event Approve(address _owner, uint256 _txId);

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!_isApproved(_txId, msg.sender), "tx already approved");
        _;
    }

    function _isApproved(uint _txId, address _addr) private view returns(bool) {
        return approved[_txId][_addr];
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId]._executed, "already executed");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredApprovals) Ownable(_owners) {
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _owners.length,
            "invalid approvals count"
        );
        requiredApprovals = _requiredApprovals;
    }

    // requiredApprovals чтобы добавллять ?

    function encode(string memory _func, string memory _arg) public pure returns(bytes memory) {
        return abi.encodeWithSignature(_func, _arg);
    }

    function approve(uint _txId) external
    onlyOwners
    txExists(_txId)
    notApproved(_txId)
    notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        approvalsCount[_txId] += 1;
        emit Approve(msg.sender, _txId);
    }

    function submit(address _to, uint256 _value, bytes calldata _data) external {
        Transaction memory newTx = Transaction({
            _to: _to,
            _value: _value,
            _data: _data,
            _executed: false
        });
        transactions.push(newTx);
        emit Submit(transactions.length - 1);
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        deposit();
    }

}
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

    // функция для добавление овнеров ?

}

contract MultiSig is Ownable {
    uint public immutable requiredApprovals;

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
    event Revoke(address _owner, uint256 _txId);
    event Executed(uint256 _txId);

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!_isApproved(_txId, msg.sender), "tx already approved");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId]._executed, "already executed");
        _;
    }

    modifier wasApproved(uint _txId) {
        require(_isApproved(_txId, msg.sender), "tx not yet approved");
        _;
    }

    modifier enoughApprovals(uint _txId) {
        require(approvalsCount[_txId] >= requiredApprovals, "not enough approvals");
        _;
    }

    function _isApproved(uint _txId, address _addr) private view returns(bool) {
        return approved[_txId][_addr];
    }

    constructor(address[] memory _owners, uint256 _requiredApprovals) Ownable(_owners) {
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _owners.length,
            "invalid approvals count"
        );
        requiredApprovals = _requiredApprovals;
    }

    // requiredApprovals функция, чтобы добавллять ?

    /**
        @notice для тестирования
     */
    function encode(string memory _func, string memory _arg) public pure returns(bytes memory) {
        return abi.encodeWithSignature(_func, _arg);
    }


    /**
        @notice сделать approve транкзации из под владельца
     */
    function approve(uint _txId) external
    onlyOwners
    txExists(_txId)
    notApproved(_txId)
    notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        approvalsCount[_txId] += 1;
        emit Approve(msg.sender, _txId);
    }

    function revoke(uint _txId) external
    onlyOwners
    txExists(_txId)
    notExecuted(_txId)
    wasApproved(_txId)
    {
        approved[_txId][msg.sender] = false;
        approvalsCount[_txId] -= 1;
        emit Revoke(msg.sender, _txId);
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

    function execute(uint _txId) external 
    txExists(_txId)
    notExecuted(_txId)
    enoughApprovals(_txId)
    {
        Transaction storage myTx = transactions[_txId];

        (bool success,) = myTx._to.call{value: myTx._value}(myTx._data);
        require(success, "tx failed");

        myTx._executed = true;
        emit Executed(_txId);
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        deposit();
    }

}



contract Receiver {
    string public message;

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function setMessage(string memory _msg) external payable {
        message = _msg;
    }
}
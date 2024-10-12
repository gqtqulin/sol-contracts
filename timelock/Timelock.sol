// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Timelock {
    address public owner;

    uint public constant MIN_DELAY = 10;
    uint public constant MAX_DELAY = 100;
    uint public constant EXPIRY_DELAY = 1000;

    mapping(bytes32 => bool) public queuedTxs;

    event Queued(
        bytes32 indexed txId,
        address indexed to,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );

    event Executed(
        bytes32 indexed txId,
        address indexed to,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner");
        _;
    }

    /**
        @notice ставим в очередь транзакцию
        @param _to с какого адреса запускаем переданную функ
        @param _value сумма сколько отправляем транзакцией
        @param _func функция запускаемая у _to
        @param _data что отправляем как параметр в функцию
        @param _timestamp когда запускаем
     */
    function queue(
        address _to,
        uint256 _value,
        string calldata _func,
        bytes calldata _data,
        uint256 _timestamp
    ) external onlyOwner returns (bytes32) {
        // можно вынести в функцию - операция повторяется в execute
        // создаем уникальный id
        // bytes32 txId = keccak256(
        //     abi.encode(
        //         _to, _value, _func, _data, _timestamp
        //     )
        // );
        bytes32 txId = generateId(
            _to, _value, _func, _data, _timestamp
        );

        // сохраняем диапазом, когда можно запустить функцию
        require(!queuedTxs[txId], "already queued");
        require(
            _timestamp >= block.timestamp + MIN_DELAY &&
            _timestamp <= block.timestamp + MAX_DELAY,
            "invalid timestamp"
        );

        queuedTxs[txId] = true;

        emit Queued(
            txId,
            _to,
            _value,
            _func,
            _data,
            _timestamp
        );

        return txId;
    }

    /**
        @notice запуск поставленной в очередь операции
     */
    function execute(
        address _to,
        uint256 _value,
        string calldata _func,
        bytes calldata _data,
        uint256 _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        // bytes32 txId = keccak256(
        //     abi.encode(
        //         _to, _value, _func, _data, _timestamp
        //     )
        // );
        bytes32 txId = generateId(
            _to, _value, _func, _data, _timestamp
        );

        // проверки на постановку в очередь и соблюдение времени выполнения
        require(queuedTxs[txId], "not queued!");
        require(block.timestamp >= _timestamp, "too early!");
        require(block.timestamp <= _timestamp + EXPIRY_DELAY, "too late!");

        delete queuedTxs[txId];

        // если указали payable функцию - берем 4 первых байта от названия в keccak256 
        // (так solidity находит какую функцию запускать)
        bytes memory data;
        if (bytes(_func).length > 0) {
            data = abi.encodePacked(
                bytes4(keccak256(bytes(_func))), _data
            );
        } else {
            data = _data;
        }

        (bool success, bytes memory resp) = _to.call{value: _value}(data);
        require(success, "tx failed!");

        emit Executed(
            txId,
            _to,
            _value,
            _func,
            _data,
            _timestamp
        );

        return resp;
    }

    /**
        @notice отменяет запуск отложенного вызова по id 
     */
    function cancel(bytes32 _txId) external onlyOwner {
        require(queuedTxs[_txId], "not queued!");
        delete queuedTxs[_txId];
    }

    /**
        @notice генерирует id отложенного вызова
        @param _address адресс
        @param _value сумма
        @param _data параметр функции
        @param _timestamp когда запускаем
     */
    function generateId(
        address _address,
        uint256 _value,
        string memory _func,
        bytes memory _data,
        uint256 _timestamp
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _address, _value, _func, _data, _timestamp
            )
        );
    }
}

/**
    
    @notice контракт для теста таймлока
*/
contract Runner {
    address public lock;
    string public message;
    mapping(address => uint) public payments;

    /**
        задаем ссылку на развенутый таймлок
     */
    constructor(address _lock) {
        lock = _lock;
    }

    /**
        эту функцию будет запускать из под контракта таймлока
        @notice задает переданный из таймлока message 
     */
    function run(string memory newMsg) external payable {
        require(msg.sender == lock, "invalid address");

        payments[msg.sender] += msg.value;
        message = newMsg;
    }

    /**
        если не вызвана функция run() - ревертим транзакцию
     */
    fallback() external payable {
        revert("using function required");
    }

    /**
        @notice служебная для получения отложенного времени транзакции
     */
    function newTimestamp() external view returns(uint) {
        return block.timestamp + 20;
    }

    /**
        @notice encode строки в байты для прокидывания
        из таймлока в run()
     */
    function prepareData(string calldata _msg) external pure returns(bytes memory) {
        return abi.encode(_msg);
    }
}
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./variables.sol";

/**
 * @title ConnectorsInterface.
 */
interface ConnectorsInterface {
    function isConnectors(string[] calldata connectorNames)
        external
        view
        returns (bool, address[] memory);
}

/**
 * @title Constants.
 * @dev Maintains common state variables across implementation.
 */
contract Constants is Variables {
    // StakeAllIndex Address.
    address internal immutable stakeAllIndex;
    // Connectors Address.
    address public immutable connectorsM1;

    constructor(address _stakeAllIndex, address _connectors) {
        connectorsM1 = _connectors;
        stakeAllIndex = _stakeAllIndex;
    }
}

/**
 * @title BaseImplementation.
 * @dev DeFi Smart Account Base.
 */
contract BaseImplementation is Constants {
    /**
     * Constructor
     * @param _stakeAllIndex Stakeall index contract address
     * @param _connectors Connector address
     */
    constructor(address _stakeAllIndex, address _connectors)
        Constants(_stakeAllIndex, _connectors)
    {}

    /**
     * @notice Decodes events.
     *
     * @param response Response to be decoded.
     */
    function decodeEvent(bytes memory response)
        internal
        pure
        returns (string memory _eventCode, bytes memory _eventParams)
    {
        if (response.length > 0) {
            (_eventCode, _eventParams) = abi.decode(response, (string, bytes));
        }
    }

    event LogCast(
        address indexed origin,
        address indexed sender,
        uint256 value,
        string[] targetsNames,
        address[] targets,
        string[] eventNames,
        bytes[] eventParams
    );

    receive() external payable {}

    /**
     * @dev Delegate the calls to Connector.
     * @param _target Connector address
     * @param _data CallData of function.
     */
    function spell(address _target, bytes memory _data)
        internal
        returns (bytes memory response)
    {
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(
                gas(),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }

    /**
     * @dev Executes calls to `targetNames`.
     * @param _targetNames Connector address
     * @param _datas CallData of function.
     * @param _origin Origin of transaction.
     */
    function _cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) internal returns (bytes32) {
        uint256 _length = _targetNames.length;
        require(_length != 0, "1: length-invalid");
        require(_length == _datas.length, "1: array-length-invalid");

        string[] memory eventNames = new string[](_length);
        bytes[] memory eventParams = new bytes[](_length);

        (bool isOk, address[] memory _targets) = ConnectorsInterface(
            connectorsM1
        ).isConnectors(_targetNames);

        require(isOk, "1: not-connector");

        for (uint256 i = 0; i < _length; i++) {
            bytes memory response = spell(_targets[i], _datas[i]);
            (eventNames[i], eventParams[i]) = decodeEvent(response);
        }

        emit LogCast(
            _origin,
            msg.sender,
            msg.value,
            _targetNames,
            _targets,
            eventNames,
            eventParams
        );
    }
}

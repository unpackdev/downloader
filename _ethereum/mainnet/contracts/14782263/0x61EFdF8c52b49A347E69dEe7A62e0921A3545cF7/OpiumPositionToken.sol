// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "./draft-ERC20PermitUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IDerivativeLogic.sol";
import "./LibDerivative.sol";
import "./LibBokkyPooBahsDateTimeLibrary.sol";

/**
    Error codes:
    - P1 = ERROR_OPIUM_POSITION_TOKEN_NOT_FACTORY
 */

/// @title Opium.OpiumPositionToken is an ERC20PermitUpgradeable child contract created by the Opium.OpiumProxyFactory. It represents a specific position (either LONG or SHORT) for a given `LibDerivative.Derivative` derivative
contract OpiumPositionToken is ERC20PermitUpgradeable {
    using LibDerivative for LibDerivative.Derivative;

    /// It describes the derivative whose position (either LONG or SHORT) is being represented by the OpiumPositionToken
    struct OpiumPositionTokenParams {
        LibDerivative.Derivative derivative;
        LibDerivative.PositionType positionType;
        bytes32 derivativeHash;
    }

    address private factory;
    OpiumPositionTokenParams private opiumPositionTokenParams;

    /// @notice It is applied to all the stateful functions in OpiumPositionToken as they are meant to be consumed only via the OpiumProxyFactory
    modifier onlyFactory() {
        require(msg.sender == factory, "P1");
        _;
    }

    // ****************** EXTERNAL FUNCTIONS ******************

    // ***** SETTERS *****

    /// @notice `it is called only once upon deployment of the contract
    /// @dev it sets the state variables that are meant to be read-only and should be consumed by other contracts to retrieve information about the derivative
    /// @param _derivativeHash bytes32 hash of `LibDerivative.Derivative`
    /// @param _positionType  LibDerivative.PositionType _positionType describes whether the present ERC20 token is LONG or SHORT
    /// @param _derivative LibDerivative.Derivative Derivative definition
    function initialize(
        bytes32 _derivativeHash,
        LibDerivative.PositionType _positionType,
        LibDerivative.Derivative calldata _derivative
    ) external initializer {
        __ERC20_init("", "");
        __EIP712_init_unchained("Opium Position Token", "1");
        __ERC20Permit_init_unchained("");
        factory = msg.sender;
        opiumPositionTokenParams = OpiumPositionTokenParams({
            derivative: _derivative,
            positionType: _positionType,
            derivativeHash: _derivativeHash
        });
    }

    /// @notice it mints a specified amount of tokens to the given address
    /// @dev can only be called by the factory contract set in the `initialize` function
    /// @param _positionOwner address of the recipient of the position tokens
    /// @param _amount amount of position tokens to be minted to the _positionOwner
    function mint(address _positionOwner, uint256 _amount) external onlyFactory {
        _mint(_positionOwner, _amount);
    }

    /// @notice it burns a specified amount of tokens owned by the given address
    /// @dev can only be called by the factory contract set in the `initialize` function
    /// @param _positionOwner address of the owner of the position tokens
    /// @param _amount amount of position tokens to be burnt
    function burn(address _positionOwner, uint256 _amount) external onlyFactory {
        _burn(_positionOwner, _amount);
    }

    // ***** GETTERS *****

    /// @notice It retrieves the address of the factory contract set in the `initialize` function
    /// @return address of the factory contract (OpiumProxyFactory)
    function getFactoryAddress() external view returns (address) {
        return factory;
    }

    /// @notice It retrieves all the stored information about the underlying derivative
    /// @return _opiumPositionTokenParams OpiumPositionTokenParams struct which contains `LibDerivative.Derivative` schema of the derivative, the `LibDerivative.PositionType` of the present ERC20 token and the bytes32 hash `derivativeHash` of the `LibDerivative.Derivative` derivative
    function getPositionTokenData() external view returns (OpiumPositionTokenParams memory _opiumPositionTokenParams) {
        return opiumPositionTokenParams;
    }

    // ****************** PUBLIC FUNCTIONS ******************

    /**
     * @notice It overrides the OpenZeppelin name() getter and returns a custom erc20 name which is derived from the endTime of the erc20 token's associated derivative's maturity, the custom derivative name chosen by the derivative author and the derivative hash
     */
    function name() public view override returns (string memory) {
        string memory derivativeAuthorCustomName = IDerivativeLogic(opiumPositionTokenParams.derivative.syntheticId).getSyntheticIdName();
        string memory derivativeHashSlice = _toDerivativeHashStringIdentifier(opiumPositionTokenParams.derivativeHash);
        bytes memory endTimeDate = _toDerivativeEndTimeIdentifier(opiumPositionTokenParams.derivative.endTime);
        bytes memory baseCustomName = abi.encodePacked(
            "Opium:",
            endTimeDate,
            "-",
            derivativeAuthorCustomName,
            "-",
            derivativeHashSlice
        );
        return
            string(
                abi.encodePacked(
                    baseCustomName,
                    opiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG ? "-LONG" : "-SHORT"
                )
            );
    }

    /**
     * @notice It overrides the OpenZeppelin symbol() getter and returns a custom erc20 symbol which is derived from the endTime of the erc20 token's associated derivative's maturity, the custom derivative name chosen by the derivative author and the derivative hash
     */
    function symbol() public view override returns (string memory) {
        string memory derivativeAuthorCustomName = IDerivativeLogic(opiumPositionTokenParams.derivative.syntheticId).getSyntheticIdName();
        string memory derivativeHashSlice = _toDerivativeHashStringIdentifier(opiumPositionTokenParams.derivativeHash);
        bytes memory endTimeDate = _toDerivativeEndTimeIdentifier(opiumPositionTokenParams.derivative.endTime);
        bytes memory customSymbol = abi.encodePacked(
            "OPIUM",
            "_",
            endTimeDate,
            "_",
            derivativeAuthorCustomName,
            "_",
            derivativeHashSlice
        );
        return
            string(
                abi.encodePacked(
                    customSymbol,
                    opiumPositionTokenParams.positionType == LibDerivative.PositionType.LONG ? "_L" : "_S"
                )
            );
    }

    // ****************** PRIVATE FUNCTIONS ******************

    /// @notice It is used to obtain a slice of derivativeHash and convert it to a string to be used as part of an Opium position token's name
    /// @param _data bytes32 representing a derivativeHash
    /// @return string representing the first 4 characters of a derivativeHash prefixed by "0x"
    function _toDerivativeHashStringIdentifier(bytes32 _data) private pure returns (string memory) {
        bytes4 result;
        assembly {
            result := or(
                and(
                    or(
                        shr(4, and(_data, 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000)),
                        shr(8, and(_data, 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00))
                    ),
                    0xffff000000000000000000000000000000000000000000000000000000000000
                ),
                shr(
                    16,
                    or(
                        shr(4, and(shl(8, _data), 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000)),
                        shr(8, and(shl(8, _data), 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00))
                    )
                )
            )
        }

        return
            string(
                abi.encodePacked(
                    "0x",
                    bytes4(0x30303030 + uint32(result) + (((uint32(result) + 0x06060606) >> 4) & 0x0F0F0F0F) * 7)
                )
            );
    }

    /// @notice It is used to convert a derivative.endTime to a human-readable date to be used as part of an Opium position token's name
    /// @dev { See the third-party library ./libs/LibBokkyPooBahsDateTimeLibrary.sol }
    /// @param _derivativeEndTime uint256 representing the timestamp of a given derivative's maturity
    /// @return bytes representing the encoding of the derivativeEndTime converted to day-month-year in the format DD/MM/YYYY
    function _toDerivativeEndTimeIdentifier(uint256 _derivativeEndTime) private pure returns (bytes memory) {
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary.timestampToDate(_derivativeEndTime);

        return
            abi.encodePacked(
                StringsUpgradeable.toString(year),
                month < 10
                    ? abi.encodePacked("0", StringsUpgradeable.toString(month))
                    : bytes(StringsUpgradeable.toString(month)),
                day < 10
                    ? abi.encodePacked("0", StringsUpgradeable.toString(day))
                    : bytes(StringsUpgradeable.toString(day))
            );
    }

    // Reserved storage space to allow for layout changes in the future.
    // The gaps left for the `OpiumPositionToken` are less than the slots allocated for the other upgradeable contracts in the protocol because the OpiumPositionToken is the only contract that is programmatically deployed (frequently), hence we want to minimize the gas cost
    uint256[30] private __gap;
}

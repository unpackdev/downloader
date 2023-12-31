// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

abstract contract MintingStages is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    /* ACCESS ROLES */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /* MINTER ROLES */
    bytes32 public constant WL_MINTER_ROLE = keccak256("WL_MINTER_ROLE");
    bytes32 public constant OG_MINTER_ROLE = keccak256("OG_MINTER_ROLE");

    /* OG MINT DETAILS */
    uint256 public _ogMintPrice;
    uint256 public _ogMintMaxPerUser;
    uint256 public _ogMintStart;
    uint256 public _ogMintEnd;

    /* WL MINT DETAILS */
    uint256 public _whitelistMintPrice;
    uint256 public _whitelistMintMaxPerUser;
    uint256 public _whitelistMintStart;
    uint256 public _whitelistMintEnd;

    /* REGULAR MINT DETAILS*/
    uint256 public _mintPrice;
    uint256 public _mintMaxPerUser;
    uint256 public _mintStart;
    uint256 public _mintEnd;

    event UpdateWLevent(address indexed sender, uint256 listLength);
    event UpdateOgEvent(address indexed sender, uint256 listLength);

    modifier OnlyAdminOrOperator() {
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(OPERATOR_ROLE, msg.sender), "Only Admin or Operator");
        _;
    }

    /// OG MINTING
    function updateOGMintPrice(uint256 price) external OnlyAdminOrOperator {
        require(price > 0, "Invalid price amount");
        _ogMintPrice = price;
    }

    function updateOGMintMax(uint256 ogMintMax) external OnlyAdminOrOperator {
        require(ogMintMax > 0, "Invalid max amount");
        _ogMintMaxPerUser = ogMintMax;
    }

    /// WL MINTING
    function updateWhitelistMintPrice(uint256 whitelistMintPrice) external OnlyAdminOrOperator {
        require(whitelistMintPrice > 0, "Invalid price amount");
        _whitelistMintPrice = whitelistMintPrice;
    }

    function updateWLMintMax(uint256 whitelistMintMax) external OnlyAdminOrOperator {
        require(whitelistMintMax > 0, "Invalid max amount");
        _whitelistMintMaxPerUser = whitelistMintMax;
    }

    // REGULAR MINTING
    function updateMintPrice(uint256 mintPrice) external OnlyAdminOrOperator {
        require(mintPrice > 0, "Invalid price amount");
        _mintPrice = mintPrice;
    }

    function updateMintMax(uint256 mintMax) external OnlyAdminOrOperator {
        require(mintMax > 0, "Invalid mint amount");
        _mintMaxPerUser = mintMax;
    }

    function updateTime(uint256 start, uint256 end) external OnlyAdminOrOperator {
        require(end > start, "End not > start");
        _mintStart = start;
        _mintEnd = end;
    }

    /// @param _minterList array of addresses
    /// @param _mintRole 0 = OG, 1 = WL
    /// @dev reverts if any address in the array is address zero
    function updateMinterRoles(address[] calldata _minterList, uint8 _mintRole) public OnlyAdminOrOperator {
        require(_mintRole == 0 || _mintRole == 1, "Error only OG=0,WL=1");
        uint256 minters = _minterList.length;
        if (minters > 0) {
            for (uint256 i; i < minters;) {
                require(_minterList[i] != address(0x0), "Invalid Address");
                _mintRole == 0 ? _grantRole(OG_MINTER_ROLE, _minterList[i]) : _grantRole(WL_MINTER_ROLE, _minterList[i]);
                unchecked {
                    ++i;
                }
            }
        }
    }

    function encodeNftParams(
        uint256 maxSupply,
        uint256 royaltyFee,
        string memory name,
        string memory symbol,
        string memory initBaseURI
    ) external pure returns (bytes memory _data) {
        _data = abi.encode(maxSupply, royaltyFee, name, symbol, initBaseURI);
    }
}

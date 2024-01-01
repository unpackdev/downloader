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
    uint256 public ogMintPrice;
    uint256 public ogMintMaxPerUser;
    uint256 public ogMintStart;
    uint256 public ogMintEnd;

    /* WL MINT DETAILS */
    uint256 public whitelistMintPrice;
    uint256 public whitelistMintMaxPerUser;
    uint256 public whitelistMintStart;
    uint256 public whitelistMintEnd;

    /* REGULAR MINT DETAILS*/
    uint256 public mintPrice;
    uint256 public mintMaxPerUser;
    uint256 public mintStart;
    uint256 public mintEnd;

    event UpdateWLevent(address indexed sender, uint256 listLength);
    event UpdateOgEvent(address indexed sender, uint256 listLength);

    modifier OnlyAdminOrOperator() {
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(OPERATOR_ROLE, msg.sender), "Only Admin or Operator");
        _;
    }

    /// OG MINTING
    function updateOGMintPrice(uint256 _price) external OnlyAdminOrOperator {
        require(_price > 0, "Invalid price amount");
        ogMintPrice = _price;
    }

    function updateOGMintMax(uint256 _ogMintMax) external OnlyAdminOrOperator {
        require(_ogMintMax > 0, "Invalid max amount");
        ogMintMaxPerUser = _ogMintMax;
    }

    /// WL MINTING
    function updateWhitelistMintPrice(uint256 _whitelistMintPrice) external OnlyAdminOrOperator {
        require(_whitelistMintPrice > 0, "Invalid price amount");
        whitelistMintPrice = _whitelistMintPrice;
    }

    function updateWLMintMax(uint256 _whitelistMintMax) external OnlyAdminOrOperator {
        require(_whitelistMintMax > 0, "Invalid max amount");
        whitelistMintMaxPerUser = _whitelistMintMax;
    }

    // REGULAR MINTING
    function updateMintPrice(uint256 _mintPrice) external OnlyAdminOrOperator {
        require(_mintPrice > 0, "Invalid price amount");
        mintPrice = _mintPrice;
    }

    function updateMintMax(uint256 _mintMax) external OnlyAdminOrOperator {
        require(_mintMax > 0, "Invalid mint amount");
        mintMaxPerUser = _mintMax;
    }

    function updateTime(uint256 _start, uint256 _end) external OnlyAdminOrOperator {
        require(_end > _start, "End not > start");
        mintStart = _start;
        mintEnd = _end;
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

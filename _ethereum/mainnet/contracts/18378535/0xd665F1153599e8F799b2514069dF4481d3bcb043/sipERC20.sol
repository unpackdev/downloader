// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC4626Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20.sol";
import "./IERC20Upgradeable.sol";
import "./IERC20Metadata.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20.sol";
import "./ERC721Enumerable.sol";
import "./OPPS.sol";

contract sipERC20 is IERC20MetadataUpgradeable, ERC4626Upgradeable {
    using SafeERC20 for IERC20;
    uint256 public deficit;
    address public opps;

    // IF THIS CALLDATA AIN'T RIGHT WE GON SHOOT ‼️
    function _tryGetSymbolFrame(
        IERC20 _asset
    ) public view returns (string memory _symbol) {
        (bool success, bytes memory returnData) = address(_asset).staticcall(
            abi.encodePacked(IERC20Metadata.symbol.selector)
        );
        require(success, "!symbol");
        (_symbol) = abi.decode(returnData, (string));
    }

    function _fingerprint8(
        address asset
    ) internal pure returns (string memory) {
        bytes memory digest = abi.encodePacked(
            keccak256(abi.encodePacked("/pintswap/checksum", address(asset)))
        );
        uint256 point = uint256(uint8(digest[0]));
        string[16] memory table = [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "a",
            "b",
            "c",
            "d",
            "e",
            "f"
        ];
        uint256 high = (point & uint256(0xf0)) >> uint256(4);
        uint256 low = point & uint256(0x0f);
        return string(abi.encodePacked(table[high], table[low]));
    }

    function _tryGetSymbol(
        IERC20Upgradeable asset
    ) internal view returns (string memory _symbol) {
        (bool success, bytes memory returnData) = address(this).staticcall(
            abi.encodePacked(this._tryGetSymbolFrame.selector, abi.encode(address(asset)))
        );
        if (!success)
            return
                string(
                    abi.encodePacked(
                        "SETUP(",
                        _fingerprint8(address(asset)),
                        ")"
                    )
                ); // UNDERCOVER BUT WE SERVED HIM ANYWAY 🔥🔥
        (_symbol) = abi.decode(returnData, (string));
    }

    function _takeName(
        string memory _name,
        address _asset,
        bool reserve
    ) internal returns (string memory name) {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        if (OPPS(opps).nameTaken(nameHash)) {
            name = string(abi.encodePacked("SETUP(", _fingerprint8(_asset), ")"));
        } else {
            if (reserve) OPPS(opps).registerName(nameHash);
            name = _name;
        }
    }
    function symbol() public view virtual override(IERC20MetadataUpgradeable, ERC20Upgradeable) returns (string memory result) {
      result = super.symbol();
    }
      

    function initialize(address underlying) public initializer {
        opps = msg.sender;
        __ERC4626_init(IERC20Upgradeable(underlying));
        __ERC20_init_unchained(
            _takeName(
                string(abi.encodePacked("sip", _tryGetSymbol(IERC20Upgradeable(underlying)))),
                underlying,
                false
            ),
            _takeName(
                string(abi.encodePacked("sip", _tryGetSymbol(IERC20Upgradeable(underlying)))),
                underlying,
                true
            )
        );
    }

    modifier isTheOpps() {
        require(
            ERC721Enumerable(opps).tokenOfOwnerByIndex(msg.sender, 0) >= 0,
            "!opps"
        );
        _;
    }

    function finna(uint256 value) public isTheOpps {
        deficit += value;
        IERC20(asset()).safeTransfer(msg.sender, value);
    }

    function push(uint256 value, uint256 profit) public isTheOpps {
        deficit -= value;
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), value + profit);
    }

    function totalAssets() public view override returns (uint256 result) {
        result = super.totalAssets() + deficit;
    }
}

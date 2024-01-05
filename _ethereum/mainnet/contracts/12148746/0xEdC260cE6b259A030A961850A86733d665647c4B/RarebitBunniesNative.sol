//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "./IERC20.sol";
import "./IERC1155MetadataURI.sol";
import "./SafeERC20.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC777RecipientUpgradeable.sol";
import "./IERC1820Registry.sol";
import "./IPERC20Vault.sol";
import "./IERC1155Uried.sol";
import "./Utils.sol";


contract RarebitBunniesNative is ERC1155HolderUpgradeable, IERC777RecipientUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    IERC1820Registry private _erc1820;
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    address public erc1155;
    address public erc777;
    address public vault;
    address public rarebitBunniesHost;
    uint256 public minTokenAmountToPegIn;

    event Minted(uint256 id, uint256 amount, address to);
    event MinTokenAmountToPegInChanged(uint256 minTokenAmountToPegIn);
    event RarebitBunniesHostChanged(address rarebitBunniesHost);
    event ERC777Changed(address erc777);
    event VaultChanged(address vault);

    function setMinTokenAmountToPegIn(uint256 _minTokenAmountToPegIn) external onlyOwner {
        minTokenAmountToPegIn = _minTokenAmountToPegIn;
        emit MinTokenAmountToPegInChanged(minTokenAmountToPegIn);
    }

    function setRarebitBunniesHost(address _rarebitBunniesHost) external onlyOwner {
        rarebitBunniesHost = _rarebitBunniesHost;
        emit RarebitBunniesHostChanged(rarebitBunniesHost);
    }

    function setERC777(address _erc777) external onlyOwner {
        erc777 = _erc777;
        emit ERC777Changed(erc777);
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
        emit VaultChanged(vault);
    }

    function tokensReceived(
        address, /*_operator*/
        address _from,
        address, /*_to,*/
        uint256, /*_amount*/
        bytes calldata _userData,
        bytes calldata /*_operatorData*/
    ) external override {
        if (_msgSender() == erc777 && _from == vault) {
            (, bytes memory userData, , address originatingAddress) = abi.decode(_userData, (bytes1, bytes, bytes4, address));
            require(originatingAddress == rarebitBunniesHost, "RarebitBunniesNative: Invalid originating address");
            (uint256 id, uint256 amount, address to) = abi.decode(userData, (uint256, uint256, address));
            IERC1155Uried(erc1155).safeTransferFrom(address(this), to, id, amount, "");
        }
    }

    function initialize(
        address _erc1155,
        address _erc777,
        address _vault
    ) public {
        erc1155 = _erc1155;
        erc777 = _erc777;
        vault = _vault;
        _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        __ERC1155Holder_init();
        __Ownable_init();
    }

    function mint(
        uint256 _id,
        uint256 _nftAmount,
        address _to
    ) public returns (bool) {
        require(_nftAmount > 0, "RarebitBunniesNative: nftAmount must be greater than 0");
        IERC1155Uried(erc1155).safeTransferFrom(_msgSender(), address(this), _id, _nftAmount, "");
        if (IERC20(erc777).balanceOf(address(this)) < minTokenAmountToPegIn) {
            IERC20(erc777).safeTransferFrom(_msgSender(), address(this), minTokenAmountToPegIn);
        }
        string memory uri = IERC1155Uried(erc1155).uri(_id);
        bytes memory data = abi.encode(_id, _nftAmount, _to, uri);
        IERC20(erc777).safeApprove(vault, minTokenAmountToPegIn);
        IPERC20Vault(vault).pegIn(minTokenAmountToPegIn, erc777, Utils.toAsciiString(rarebitBunniesHost), data);
        emit Minted(_id, _nftAmount, _to);
        return true;
    }
}

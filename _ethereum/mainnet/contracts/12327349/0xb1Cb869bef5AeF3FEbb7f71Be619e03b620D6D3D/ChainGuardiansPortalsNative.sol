//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC777RecipientUpgradeable.sol";
import "./IERC1820Registry.sol";
import "./Initializable.sol";
import "./IVault.sol";
import "./IChainGuardiansToken.sol";
import "./Utils.sol";


contract ChainGuardiansPortalsNative is ERC721HolderUpgradeable, IERC777RecipientUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    IERC1820Registry private _erc1820;
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    IChainGuardiansToken public cgt;
    IERC20 public transportToken;
    IVault public vault;
    address public chainGuardiansPortalsHost;
    uint256 public minTokenAmountToPegIn;

    event Wrapped(uint256 tokenId, address to);
    event MinTokenAmountToPegInChanged(uint256 minTokenAmountToPegIn);
    event ChainGuardiansPortalsHostChanged(address chainGuardiansPortalsHost);
    event TransportTokenChaged(address transportToken);
    event VaultChanged(address vault);

    function setMinTokenAmountToPegIn(uint256 _minTokenAmountToPegIn) external onlyOwner {
        minTokenAmountToPegIn = _minTokenAmountToPegIn;
        emit MinTokenAmountToPegInChanged(minTokenAmountToPegIn);
    }

    function setChainGuardiansPortalsHost(address _chainGuardiansPortalsHost) external onlyOwner {
        chainGuardiansPortalsHost = _chainGuardiansPortalsHost;
        emit ChainGuardiansPortalsHostChanged(chainGuardiansPortalsHost);
    }

    function setTransportToken(address _transportToken) external onlyOwner {
        transportToken = IERC20(_transportToken);
        emit TransportTokenChaged(_transportToken);
    }

    function setVault(address _vault) external onlyOwner {
        vault = IVault(_vault);
        emit VaultChanged(_vault);
    }

    function tokensReceived(
        address, /*_operator*/
        address _from,
        address, /*_to,*/
        uint256, /*_amount*/
        bytes calldata _userData,
        bytes calldata /*_operatorData*/
    ) external override {
        if (_msgSender() == address(transportToken) && _from == address(vault)) {
            (, bytes memory userData, , address originatingAddress) = abi.decode(_userData, (bytes1, bytes, bytes4, address));
            require(originatingAddress == chainGuardiansPortalsHost, "ChainGuardiansPortalsNative: Invalid originating address");
            (uint256 tokenId, uint256 attrs, address to) = abi.decode(userData, (uint256, uint256, address));
            cgt.updateAttributes(tokenId, attrs, new uint256[](0));
            cgt.safeTransferFrom(address(this), to, tokenId);
        }
    }

    function initialize(
        address _cgt,
        address _transportToken,
        address _vault
    ) public initializer {
        cgt = IChainGuardiansToken(_cgt);
        transportToken = IERC20(_transportToken);
        vault = IVault(_vault);
        _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        __ERC721Holder_init();
        __Ownable_init();
    }

    function wrap(uint256 _tokenId, address _to) public returns (bool) {
        cgt.safeTransferFrom(_msgSender(), address(this), _tokenId);
        if (transportToken.balanceOf(address(this)) < minTokenAmountToPegIn) {
            transportToken.safeTransferFrom(_msgSender(), address(this), minTokenAmountToPegIn);
        }
        (uint256 attrs, ) = cgt.getProperties(_tokenId);
        bytes memory data = abi.encode(_tokenId, attrs, _to);
        transportToken.safeApprove(address(vault), minTokenAmountToPegIn);
        vault.pegIn(minTokenAmountToPegIn, address(transportToken), Utils.toAsciiString(chainGuardiansPortalsHost), data);
        emit Wrapped(_tokenId, _to);
        return true;
    }
}

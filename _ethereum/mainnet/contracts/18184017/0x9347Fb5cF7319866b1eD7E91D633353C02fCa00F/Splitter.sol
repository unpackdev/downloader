// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC777Recipient.sol";
import "./IERC777.sol";
import "./IERC1820Registry.sol";


import "./CommunityList.sol";
import "./CommunityRegistry.sol";

import "./BlackHolePrevention.sol";
import "./IRegistryConsumer.sol";

import "./console.sol";

contract Splitter is IERC777Recipient, BlackHolePrevention {

   function version() public view virtual returns (uint256) {
        return 20230717;
    }

    address public constant REGISTRY_ADDRESS = 0x1e8150050A7a4715aad42b905C08df76883f396F;
    IRegistryConsumer constant _galaxisRegistry = IRegistryConsumer(REGISTRY_ADDRESS); // Galaxis Registry contract

    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => bool) public hasBeenOfficalERC777;

    bytes32 public constant COMMUNITY_REGISTRY_ADMIN_ROLE = keccak256("COMMUNITY_REGISTRY_ADMIN");

    string public constant COMMUNITY_LIST      = "COMMUNITY_LIST";
    string constant GALAXIS_WALLET             = "GALAXIS_WALLET";

    /*
    Galaxis (owner) wallett address
    It is shared state between all marketplace proxies. 
    */
    // address payable public immutable companyAddress;

    /*
    Company shares from royalty, expressed in ten-thousandths
    It is shared state between all marketplace proxies. 
    To change it, upgrade this contract.
    */

    uint32 public communityId;

    address payable[] public wallets;
    uint16[] public shares;
    
    bool initialised;

    constructor() { // GOLDEN SPLITTER :-)
        initialised = true;
    }

    function init(
        address _owner,
        uint32  _community_id,
        address payable[] memory _wallets,
        uint16[] memory _shares
    ) external  {
        require(!initialised,"Splitter : already initialised");
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        _updateWalletsAndShares(_wallets, _shares);
        communityId = _community_id;
        _transferOwnership(_owner);
        initialised = true;
    }

    function companyShares() internal view returns (uint16) {
        return uint16(_galaxisRegistry.getRegistryUINT("GALAXIS_ROYALTY_SPLIT"));
    }

    /**
     * @dev Royalties splitter
     */
    receive() external payable {
        _split(msg.value);
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256 __amount,
        bytes calldata,
        bytes calldata
    ) external override {
         if (msg.sender == address(_getAcceptedERC777())) {
            hasBeenOfficalERC777[msg.sender] = true;
        } else {
            require(hasBeenOfficalERC777[msg.sender], "Splitter: Invalid ERC777 address!");
        }
        _splitERC777(msg.sender,__amount);
    }

    /**
     * @dev Admin: Update wallets and shares
     */
    function updateWalletsAndShares(address payable[] memory _wallets, uint16[] memory _shares) external  {
        CommunityList communityList = CommunityList(_galaxisRegistry.getRegistryAddress(COMMUNITY_LIST));
        (, address crAddr, ) = communityList.communities(communityId);
        require(crAddr != address(0), "MarketplaceFactory: Invalid community ID");
        CommunityRegistry communityRegistry = CommunityRegistry(crAddr);
        require(
            communityRegistry.isUserCommunityAdmin(COMMUNITY_REGISTRY_ADMIN_ROLE, msg.sender),
            "MarketplaceFactory: not a community admin"
        );
        _updateWalletsAndShares(_wallets,_shares);
    }

    function _updateWalletsAndShares(address payable[] memory _wallets, uint16[] memory _shares) internal {
        require(
            _wallets.length == _shares.length && _wallets.length > 0,
            "PaymentSplitter: Must have at least 1 output wallet"
        );
        uint16 totalShares = 0;
        for (uint8 j = 0; j < _shares.length; j++) {
            totalShares += _shares[j];
        }
        require(totalShares == 10000, "PaymentSplitter: Shares total must be 10000");
        shares = _shares;
        wallets = _wallets;
    }

    /**
     * @dev Internal output splitter
     */
    function _split(uint256 _amount) internal {
        address companyAddress = _galaxisRegistry.getRegistryAddress(GALAXIS_WALLET);
        uint256 companyPayment = (companyShares() * _amount) / 10000;
        (bool sent, ) = companyAddress.call{value: companyPayment}("");
        uint256 remaining = _amount - companyPayment;
        for (uint256 i = 0; i < wallets.length; i++) {
            (sent, ) = wallets[i].call{value: (remaining * shares[i]) / 10000}("");
            require(sent, "Splitter: Failed to send ETH");
        }
    }

    function _splitERC777(address token,uint256 _amount) private {
        address companyAddress = _galaxisRegistry.getRegistryAddress(GALAXIS_WALLET);
        uint256 companyPayment = (companyShares() * _amount) / 10000;
        IERC777(token).send(companyAddress, companyPayment, "");

        uint256 remaining = _amount - companyPayment;
        for (uint256 i = 0; i < wallets.length; i++) {
            IERC777(token).send(wallets[i], (remaining * shares[i]) / 10000, "");
        }
    }

    function _getAcceptedERC777() internal view returns (IERC777) {
        return IERC777(_galaxisRegistry.getRegistryAddress("MARKETPLACE_ACCEPTED_ERC777"));
    }

    struct WalletAndShare {
        address _address;
        uint256 share;
    }

    function getWalletsAndShares() external view returns (WalletAndShare[] memory) {
        WalletAndShare[] memory walletsAndShares = new WalletAndShare[](wallets.length);
        for (uint256 i = 0; i < wallets.length; i++) {
            walletsAndShares[i] = WalletAndShare(wallets[i], shares[i]);
        }
        return walletsAndShares;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title TreeLogin
 * @dev made by Treemaru Studio
 */

import "./AccessControl.sol";

contract TreeLogin is AccessControl {
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

    struct ValidTx {
        address[] coldWallets;
        uint256 blockStamp;
    }

    mapping(address => ValidTx) tempValidTx;

    mapping(address => address[]) addressLink;
    mapping(address => uint256) addressSaved;
    uint256 numberHotWallets;
    address addressTreeLoginNFT;
    uint256[] idsNFTs;
    uint256 public maxLinksPerWallet = 2;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MOD_ROLE, msg.sender);
        numberHotWallets = 0;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setAddressTLNFT(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        addressTreeLoginNFT = _address;
    }

    function setMaxLinksPerWallet(uint256 _numb)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxLinksPerWallet = _numb;
    }

    function deleteOwnershipLinks(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        delete addressLink[_address];
    }

    //Set IDs for TreeLogin NFTs (erc1155 ids)
    function setListNFTIds(uint256[] memory _ids)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        idsNFTs = _ids;
    }

    //Get TreeLogin NFTs balance on address
    function getTLNFTBalance(address _addr) external view returns (uint256) {
        uint256 sumBalance = 0;
        for (uint256 i = 0; i < idsNFTs.length; i++) {
            (bool success, bytes memory data) = addressTreeLoginNFT.staticcall(
                abi.encodeWithSignature(
                    "balanceOf(address,uint256)",
                    _addr,
                    idsNFTs[i]
                )
            );
            require(success, "Callback ERROR");
            sumBalance += abi.decode(data, (uint256));
        }
        return sumBalance;
    }

    //validate ownership
    function addValidTX(address _hotWallet, address[] memory _addresses)
        external
        onlyRole(MOD_ROLE)
    {
        tempValidTx[_hotWallet] = ValidTx(_addresses, block.timestamp);
    }

    function getTempTx(address _address) external view returns (uint256) {
        return tempValidTx[_address].blockStamp;
    }

    function checkAddressIsSaved(address _address)
        external
        view
        returns (uint256)
    {
        return addressSaved[_address];
    }

    function getOwnershipData(address _address)
        external
        view
        returns (address[] memory)
    {
        return addressLink[_address];
    }

    function getNumberHotWallets() external view returns (uint256) {
        return numberHotWallets;
    }

    //add hot wallets and corresponding cold to storage
    function addAddresses(address[] memory _addresses, uint256 _timeStamp)
        external
        callerIsUser
    {
        require(
            tempValidTx[msg.sender].blockStamp > 0,
            "This Ownership was not authorized"
        );
        uint256 balanceTLNFT = this.getTLNFTBalance(msg.sender);
        require(balanceTLNFT > 0, "No TreeLogin NFTs");
        require(_addresses.length <= balanceTLNFT, "Not enough TreeLogin NFTs");
        require(_addresses.length <= maxLinksPerWallet, "Too many wallets");
        for (uint256 j = 0; j < _addresses.length; j++) {
            require(
                addressSaved[_addresses[j]] != 1,
                "Already Linked Cold Wallet"
            );
            require(
                _addresses[j] == tempValidTx[msg.sender].coldWallets[j],
                "Wrong Cold Wallets"
            );
        }
        require(
            tempValidTx[msg.sender].blockStamp == _timeStamp,
            "Wong Validation Code"
        );
        address[] memory oldLinks = this.getOwnershipData(msg.sender);
        for (uint256 k = 0; k < oldLinks.length; k++) {
            addressSaved[oldLinks[k]] = 0;
        }
        addressLink[msg.sender] = _addresses;
        for (uint256 j = 0; j < _addresses.length; j++) {
            addressSaved[_addresses[j]] = 1;
        }
        numberHotWallets++;
        delete tempValidTx[msg.sender];
    }

    //if you quickly wants to check balance from a SC.
    //Be sure the SC has the function balanceOf(address)
    function getBalanceOnProject(address _scAddress, address _hotWallet)
        external
        view
        returns (uint256)
    {
        uint256 sumBalance = 0;
        address[] memory linkedAddresses = addressLink[_hotWallet];
        for (uint256 i = 0; i < linkedAddresses.length; i++) {
            (bool success, bytes memory data) = address(_scAddress).staticcall(
                abi.encodeWithSignature(
                    "balanceOf(address)",
                    linkedAddresses[i]
                )
            );
            require(success, "Callback ERROR");
            sumBalance += abi.decode(data, (uint256));
        }
        return sumBalance;
    }
}

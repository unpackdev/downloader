// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC777.sol";
import "./Ownable.sol";
import "./IERC777Recipient.sol";
import "./IERC1820Registry.sol";

contract Splitter is IERC777Recipient, Ownable {
    event ETHPaymentReceived(address from, uint256 amount);
    event DUSTPaymentReceived(address from, uint256 amount);

    event CommunityShareChanged(address _from, uint256 _share);
    event CompanyShareChanged(address _from, uint256 _share);
    event ArtistShareChanged(
        address _from,
        uint256 _share,
        uint256 _artistIndex
    );

    event CommunityOwnerAddressChanged(address _address);
    event CompanyAddressChanged(address _address);
    event ArtistAddressChanged(address _address, uint256 _artistIndex);

    address private tokenContractAddress; // ERC777 NFT contract address
    address private communityOwnerAddress; // community owner, provide in constructor
    address private companyAddress; // company address, provide in constructor
    address[] private artistAddresses;

    uint256 private companyShares;
    uint256 private communityShares;
    uint256[] private artistShares; //index of share corresponding to artist should match index of artis in artistAddresses

    IERC777 private tokenContract; // DUST ERC777 NFT token contract

    IERC1820Registry private _erc1820 =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    constructor(
        address _communityOwnerAddress,
        address _companyAddress,
        uint256 _companyShares,
        uint256 _communityShares,
        address[] memory _artistAddresses,
        uint256[] memory _artistShares,
        address _tokenContractAddress
    ) {
        require(
            _communityOwnerAddress != address(0),
            "Cannot be ZERO address."
        );
        require(_companyAddress != address(0), "Cannot be ZERO address.");
        communityOwnerAddress = _communityOwnerAddress;
        companyAddress = _companyAddress;

        require(
            _artistShares.length <= 5,
            "At most 5 artists in splitter contract"
        );
        require(
            _artistShares.length == _artistAddresses.length,
            "Artist address or artist shares missing"
        );
        for (uint256 i = 0; i < _artistAddresses.length; i++) {
            require(
                _artistAddresses[i] != address(0),
                "Cannot be ZERO address."
            );
            artistAddresses.push(_artistAddresses[i]);
        }
        for (uint256 i = 0; i < _artistShares.length; i++) {
            require(
                _artistShares[i] > 0,
                "Artist shares must be positive integer!"
            );
            artistShares.push(_artistShares[i]);
        }

        require(
            _communityShares > 0,
            "Community shares must be positive integer!"
        );
        communityShares = _communityShares;

        require(_companyShares > 0, "Company shares must be positive integer!");
        companyShares = _companyShares;
        
        require(_tokenContractAddress != address(0), "Token contract cannot be ZERO address.");
        tokenContractAddress = _tokenContractAddress;
        tokenContract = IERC777(_tokenContractAddress); // initialize the NFT contract
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        ); // register self with IERC1820 registry
    }

    // split upon receiving ETH payment
    receive() external payable virtual {
        emit ETHPaymentReceived(msg.sender, msg.value);
        bool success;

        uint256 _totalShares = getTotalShares();
        uint256 communityPayment = (communityShares * msg.value) / _totalShares;
        (success, ) = communityOwnerAddress.call{value: communityPayment}("");
        require(success, "Transfer failed.");

        uint256 companyPayment = (companyShares * msg.value) / _totalShares;
        (success, ) = companyAddress.call{value: companyPayment}("");
        require(success, "Transfer failed.");

        for (uint256 i = 0; i < artistShares.length; i++) {
            uint256 artistPayment = (artistShares[i] * msg.value) /
                _totalShares;
            (success, ) = artistAddresses[i].call{value: artistPayment}("");
            require(success, "Transfer failed.");
        }
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        require(msg.sender == tokenContractAddress, "Invalid token!");
        // Tokens were sent to the splitter
        emit DUSTPaymentReceived(from, amount);
        uint256 _totalShares = getTotalShares();
        uint256 communityPayment = (communityShares * amount) / _totalShares;
        tokenContract.send(communityOwnerAddress, communityPayment, "");

        uint256 companyPayment = (companyShares * amount) / _totalShares;
        tokenContract.send(companyAddress, companyPayment, "");
        for (uint256 i = 0; i < artistShares.length; i++) {
            uint256 artistPayment = (artistShares[i] * amount) / _totalShares;
            tokenContract.send(artistAddresses[i], artistPayment, "");
        }
    }

    function getTotalShares() public view returns (uint256) {
        uint256 _totalShares = communityShares + companyShares;
        for (uint256 i = 0; i < artistShares.length; i++) {
            _totalShares = _totalShares + artistShares[i];
        }
        return _totalShares;
    }

    function setCompanyShares(uint256 _shares) external onlyOwner {
        require(_shares > 0, "Company shares must be positive integer!");
        companyShares = _shares;
        emit CompanyShareChanged(msg.sender, _shares);
    }

    function getCompanyShares() external view returns (uint256) {
        return companyShares;
    }

    function setCommunityShares(uint256 _shares) external onlyOwner {
        require(_shares > 0, "Community shares must be positive integer!");
        communityShares = _shares;
        emit CommunityShareChanged(msg.sender, _shares);
    }

    function getCommunityShares() external view returns (uint256) {
        return communityShares;
    }

    function setArtistShares(uint256 _shares, uint256 _artistIndex)
        external
        onlyOwner
    {
        require(_artistIndex < artistAddresses.length, "Invalid index!");
        require(_shares > 0, "Artist shares must be positive integer!");
        artistShares[_artistIndex] = _shares;
        emit ArtistShareChanged(msg.sender, _shares, _artistIndex);
    }

    function getArtistShares() external view returns (uint256[] memory) {
        return artistShares;
    }

    function getCommunityOwnerAddress() external view returns (address) {
        return communityOwnerAddress;
    }

    // change community owner address
    function setCommunityOwnerAddress(address _communityOwnerAddress)
        external
        onlyOwner
    {
        require(
            _communityOwnerAddress != address(0),
            "Cannot be ZERO address."
        );
        communityOwnerAddress = _communityOwnerAddress;
        emit CommunityOwnerAddressChanged(communityOwnerAddress);
    }

    function getCompanyAddress() external view returns (address) {
        return companyAddress;
    }

    // change company address
    function setCompanyAddress(address _companyAddress) external onlyOwner {
        require(_companyAddress != address(0), "Cannot be ZERO address.");
        companyAddress = _companyAddress;
        emit CompanyAddressChanged(companyAddress);
    }

    function getArtistAddresses() external view returns (address[] memory) {
        return artistAddresses;
    }

    function setArtistAddress(address _address, uint256 _artistIndex)
        external
        onlyOwner
    {
        require(_artistIndex < artistAddresses.length, "Invalid index!");
        require(_address != address(0), "Cannot be ZERO address.");
        artistAddresses[_artistIndex] = _address;
        emit ArtistAddressChanged(_address, _artistIndex);
    }
}

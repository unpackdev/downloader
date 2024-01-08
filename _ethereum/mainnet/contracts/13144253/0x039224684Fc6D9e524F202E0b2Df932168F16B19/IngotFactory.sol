// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IFactoryERC721.sol";
import "./Ingot.sol";

contract IngotFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Sent(address indexed payee, uint256 amount, uint256 balance);

    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "https://ggy0vyi8rk.execute-api.us-east-1.amazonaws.com/final";

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Ingots Item Sale";
    }

    function symbol() override external pure returns (string memory) {
        return "IGF";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return 1;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        emit Transfer(_from, _to, 0);
    }

    function mint(uint256 numberToMint, address _toAddress) override payable public {

        require(msg.value >= 0.03 ether * numberToMint, "Need to send at least 0.03 ether per ingot");

        require(canMint(numberToMint));


        Ingot ingot = Ingot(nftAddress);

        for (uint256 i=0; i<numberToMint;i++){
            ingot.mintTo(_toAddress);
        }
    }

    function totalSupply() public view returns (uint256) {
        
        Ingot ingot = Ingot(nftAddress);
        return 5000 - ingot.totalSupply();
    }

    function canMint(uint256 numberToMint) override public view returns (bool) {

        if (numberToMint > 20){
            return false;
        }

        Ingot ingot = Ingot(nftAddress);
        uint256 ingotSupply = ingot.totalSupply();

        return ingotSupply <= (5000 - numberToMint);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    function getBalance() public view onlyOwner returns (uint256){
        return address(this).balance;
    }

    function withdraw() public onlyOwner returns (uint256){
        uint256 balance = address(this).balance;
        payable(owner()).transfer(address(this).balance);
        emit Sent(msg.sender, balance, address(this).balance);
        return balance;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}

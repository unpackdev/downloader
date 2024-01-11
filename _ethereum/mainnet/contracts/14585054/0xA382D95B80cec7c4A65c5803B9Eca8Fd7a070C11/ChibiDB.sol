// SPDX-License-Identifier: MIT
// chibidbs.com                                                                     

pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./MerkleProof.sol";

import "./ERC721Accesslist.sol";

                                                             
/*                                                                             
 * @title ChibiDBs
 * ChibiDBs - a contract for the ChibiDBs


                          @@%%%%%%%%%%%%%%%%%%%%%@@                             
                          @@....                .@@                             
                          @@**   @@@@@@@@    *   @@                             
                          @@..                   @@                             
                          @@..     .@@           @@@@*@@                        
                          @@..     .@@           @@   @@                        
                          @@..     .@@        @@.  @@@                          
                            @@...   ..@@      ..@....@                          
                                                                                
                                                                    
 */
contract ChibiDB is ERC721Accesslist {

    // set the max supply ever - although we may lock this to a lower number this sets a total upper bound
    uint256 constant  maxEverSupply = 6969;
    uint256  public  maxSupply = 1000;  // current release limit - can change to allow second mint, or to allow accesslist limits
    bool public changeSupplyLocked = false; // fix the max supply for good
    bool public publicSaleActive = false;   //public sale active
    uint256 public basePrice = 40000000000000000; //0.040 ETH
    uint256 public accesslistPrice = 40000000000000000; //0.040 ETH
    uint public maxTokenPurchase = 10;   // what's the max someone can buy
    uint public maxAccesslistPurchase = 2;   // what's the max someone on the access list can buy
    address constant withdrawAddress = 0xEF8087375c2Cc1DCdF7B753802117fF9Dc935a57;

    // set provenance
    string public PROVENANCE;

    // url data for the meta data
    string public tokenURIPrefix = "";

    constructor()
        ERC721Accesslist("ChibiDBs", "CHIBIDBS")
    {
    }

    // allow transfer to the owner or a preconfigured address
    function withdraw() external  {
        require(owner() == _msgSender() || withdrawAddress == _msgSender() , "Ownable: caller is not the owner");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    // token meta data url functions
    function baseTokenURI() override public view returns (string memory) {
        return tokenURIPrefix;
    }

    function updateTokenURIPrefix(string memory newPrefix) external onlyOwner {
        tokenURIPrefix = newPrefix;
    }

    // get and set the public sale state
    function setPublicSale(bool _setSaleState) public onlyOwner{
        publicSaleActive = _setSaleState;
    }    
        
 
    // allow us to slowly release up to the max ever supply
    function setMaxSupply(uint _maxSupply) public onlyOwner{
        if (_maxSupply <= maxEverSupply && !changeSupplyLocked)
            maxSupply = _maxSupply;
    }    

    function lockSupply() virtual public onlyOwner{
        changeSupplyLocked = true;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    // set a new price for the main mint
    function updatePrice(uint _newPrice) public onlyOwner{
        basePrice =  _newPrice;
    }

    // set a new price for the access list mint
    function updateAccesslistPrice(uint newPrice) public onlyOwner{
        accesslistPrice =  newPrice;
    }    

    // update the max number that can be minted in a single transaction in a public mint
    function updateMaxTokenPurchase(uint _maxTokenPurchase) public onlyOwner{
        maxTokenPurchase =  _maxTokenPurchase;
    }

    // update the total number that can be minted via an accesslist
    function updateMaxAccesslistPurchase(uint _maxAccesslistPurchase) public onlyOwner{
        maxAccesslistPurchase =  _maxAccesslistPurchase;
    }

    // allow the owner to pre-mint or save a number of tokens
    function reserveTokens(uint _amount, address _receiver) public onlyOwner {        

        uint256 newSupply = totalSupply + _amount;
        require(newSupply <= maxSupply, "MAX_SUPPLY_EXCEEDED");

        for (uint256 i = 0; i < _amount; i++) {
            _mint(_receiver, totalSupply + i);
        }    
        // update the total supply
        totalSupply = newSupply;    
    }

    // mint 
    function mint(uint256 amount) external payable {
        require(amount != 0, "INVALID_AMOUNT");
        require(publicSaleActive, "SALE_CLOSED");
        require(amount <= maxTokenPurchase, "AMOUNT_EXCEEDS_MAX_PER_CALL");
        require(amount * basePrice <= msg.value, "WRONG_ETH_AMOUNT");

        uint256 newSupply = totalSupply + amount;
        require(newSupply <= maxSupply, "MAX_SUPPLY_EXCEEDED");

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply + i);
        }
        // update the totaly supply
        totalSupply = newSupply;
    }

    function accesslistMint(uint256 amount, bytes32[] calldata proof) public payable {
   //     string memory payload = string(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, accesslistRoot, keccak256(abi.encodePacked(msg.sender))), "BAD_MERKLE_PROOF");

        require(accesslistSaleActive, "SALE_CLOSED");
        require(amount <= maxTokenPurchase, "AMOUNT_EXCEEDS_MAX_PER_CALL");
        require(amount * accesslistPrice <= msg.value, "WRONG_ETH_AMOUNT");
        require(accesslistMinted[msg.sender] + amount <= maxAccesslistPurchase, "EXCEEDS_ALLOWANCE"); 

        uint256 newSupply = totalSupply + amount;
        require(newSupply <= maxSupply, "MAX_SUPPLY_EXCEEDED");

        accesslistMinted[msg.sender] += amount;
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply + i);
        }
        // update the totaly supply
        totalSupply = newSupply;
    }

}

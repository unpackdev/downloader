//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./Strings.sol";
import "./console.sol";
import "./ERC721A.sol";


contract Shell is ERC721A, Ownable  {
    using Strings for uint256;

    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MAX_PUBLIC = 9000;
    uint256 private constant MAX_TEAM = 1000;
    uint256 private constant maxPerAddressDuringMint = 10;
    
    uint256 public TOTAL_SUPPLY_TEAM;

    address public teamWallet = 0x18D2EF7Be1c45c4CAE4Ddd47f947202186B40646;

    string public baseURI;
    bool public isPaused;

    mapping(address => uint256) amountNFTperWallet;

    constructor(string memory _baseURI)
        ERC721A("Shell", "SP")
    {
        baseURI = _baseURI;
    }

    /**
    * @notice This contract can't be called by other contracts
    */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is another contract");
        _;
    }

    /**
    * @notice Override the first Token ID# for ERC721A
    */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Mint function for public
     * @param _quantity Amount of NFTs the user wants to mint
     * @param _address Address that receives nfts 
     **/
    function publicMint (address _address, uint256 _quantity ) external callerIsUser{
        require(!isPaused, "Contract is paused");
        require(_quantity > 0, "No 0 mints");
        require(
            amountNFTperWallet[msg.sender] + _quantity <=
                maxPerAddressDuringMint,
            "You can only get 10 nfts"
        );

        require(
            totalSupply() + _quantity <= MAX_PUBLIC,
            "Max supply exceeded"
        );

        amountNFTperWallet[msg.sender] += _quantity;
        _safeMint(_address, _quantity);
    }

    /**
     * @notice Mint function for team
     * @param _quantity Amount of NFTs the user wants to mint
     * @param _address Address that receives nfts 
     **/
    function teamMint (address _address, uint256 _quantity ) external callerIsUser{
        require(!isPaused, "Contract is paused");
        require(msg.sender == teamWallet, "You are not in the team");
        require(TOTAL_SUPPLY_TEAM + _quantity <= MAX_TEAM , "No team mint left" );
        _safeMint(_address, _quantity);
    }

    /**
     * @notice Get the token URI of an NFT by his ID
     * @param _tokenId the id of the NFT you want to have the uri of the metadatas
     * @return the token URI of an NFT by his ID
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for non existant token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
     * @notice Change the team wallet
     * @param _address new team account
     **/
    function changeTeamWallet (address _address ) external onlyOwner{
        teamWallet = _address;
    }

    /**
     * @notice set new baseURI
     * @param _baseURI new base uri
     **/
    function setBaseUri(string memory _baseURI) external onlyOwner{
        baseURI = _baseURI;
    }

    /**
     * @notice pause or unpause the smart contract
     * @param _isPaused true or false
     **/
    function setIsPaused(bool _isPaused) external onlyOwner{
        isPaused = _isPaused;
    }

    /**
     * @notice withdraw function
     **/
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
    }

    /**
     * @notice Not allowing receiving ethers outside minting functions
     **/
    receive() external payable {
        revert("Only if you mint");
    }
}

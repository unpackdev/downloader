// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

/**
 * @dev contract module which defines  NFT Collection
 * and all the interactions it uses
 */
contract Zombronies is ERC721Enumerable, Ownable {
    using Strings for uint256;

    //@dev Attributes for NFT configuration
    string internal baseURI; 
    uint256 public cost = 0.06 ether;
    uint256 public maxSupply = 10000;
    uint256 internal pauseLimit = maxSupply;
    uint256 public maxMintAmount =10;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256[]) internal tokenIdsToWallet;
    mapping(uint256 => string) private _tokenURIs;  
    mapping(address => bool) presaleAddress;
    bool public presale;
    bool public paused;
    bool public revealed;
    // @dev inner attributes of the contract
    
    /**
     * @dev Create an instance of Zombronies contract
     * @param _initBaseURI Base URI for NFT metadata.
     */
    constructor(
        string memory _initBaseURI
    ) ERC721("Zombronies", "Zombronies"){
        setBaseURI(_initBaseURI);
    }
    
    /**
     * @dev get base URI for NFT metadata
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    
    function reveal(string memory _newURI) public onlyOwner {
        setBaseURI(_newURI);
        revealed = true;
    }
    
    /**
     * @dev Mint edition to a wallet
     * @param _to wallet receiving the edition(s).
     * @param _mintAmount number of editions to mint.
     */
    function mint(address _to, uint256 _mintAmount) public payable {
        require(!paused,"Sales are paused");
        if(presale == true)
            require(presaleAddress[msg.sender] == true,"Not allowed in pre-sale");
            
        uint256 supply = totalSupply();
        require(
            supply + _mintAmount <= pauseLimit,
            "Not enough mintable editions !"
        );

        require(
            msg.value == cost * _mintAmount,
            "Incorrect transaction amount."
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
            tokenIdsToWallet[_to].push() = supply + i;
        }
    }

    /**
     * @dev whitelistMint edition to a wallet
     * @param _to wallet receiving the edition(s).
     * @param _mintAmount number of editions to mint.
     */    
    function freeMint(address _to, uint256 _mintAmount) public {
        uint256 supply = totalSupply();
        require(
                _mintAmount <= whitelist[msg.sender],
                "Amount exceeds allowance"
            );
            whitelist[msg.sender] -= _mintAmount;
		for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
            tokenIdsToWallet[_to].push() = supply + i;
        }
    }
    
    /**
     * @dev get balance contained in the smart contract
     */
    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev change cost of NFT
     * @param _newCost new cost of each edition
     */
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    /**
     * @dev restrict max mintable amount of edition at a time
     * @param _newmaxMintAmount new max mintable amount
     */
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    /**
     * @dev change metadata uri
     * @param _newBaseURI new URI for metadata
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev set pause limit
     * @param _pauseLimit pause limit
     */
    function setPauseLimit(uint256 _pauseLimit) public onlyOwner {
        pauseLimit = _pauseLimit;
    }

    /**
     * @dev Disable minting process
     */
    function pause() public onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Activate presaleAddress
     */
    function activatePresale() public onlyOwner {
        presale = !presale;
    } 
    
    /**
     * @dev Activate presaleAddress
     */
    function presaleMembers(address[] memory _presaleAddress) public onlyOwner {
        for(uint i = 0; i< _presaleAddress.length; i++)
            presaleAddress[_presaleAddress[i]] = true;
    } 
    
    /**
     * @dev Add user to white list
     * @param _user Users wallet to whitelist
     */
    function whitelistUserBatch(
        address[] memory _user,
        uint256[] memory _amount
    ) public onlyOwner {
        require(_user.length == _amount.length);
        for (uint256 i = 0; i < _user.length; i++)
            whitelist[_user[i]] = _amount[i];
    }

    /**
     * @dev Get token URI
     * @param tokenId ID of the token to retrieve
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
        {
        require(
            _exists(tokenId),
            "URI query for nonexistent token"
        );
        
        if(revealed == false)
            return baseURI;
        else {
            if (bytes(_tokenURIs[tokenId]).length == 0) {
                string memory currentBaseURI = _baseURI();
                return
                    bytes(currentBaseURI).length > 0
                        ? string(
                            abi.encodePacked(
                                currentBaseURI,
                                tokenId.toString(),
                                ".json"
                            )
                        )
                        : "";
            } else return _tokenURIs[tokenId];
        }
    }
    
      function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
      }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract NoBrainers is ERC721Enumerable, ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant RESERVE_NFT = 200;
    uint256 public constant PUBLIC_NFT = 4900;
    uint256 public constant MAX_NFT = RESERVE_NFT + PUBLIC_NFT;
    uint256 public constant NFT_PRICE = 0.08 ether;

    uint256 public constant PRESALE_PURCHASE_LIMIT = 4;
    uint256 public constant MAINSALE_PURCHASE_LIMIT = 7;

    uint256 public publicTotalSupply;

    string private baseURI;
    string private blindURI;
    string private reserveURI;

    bool public reveal;
    bool public isPreSaleActive;
    bool public isMainSaleActive;

    address public communityTreasury;
    address public charity;

    mapping(address => bool) public presaleAccess;

    mapping(address => uint256) public presaleClaimed;
    mapping(address => uint256) public mainSaleClaimed;
    mapping(address => uint256[]) public giveaway;

    constructor(address _communityTreasury, address _charity) ERC721("No Brainers", "NBRN") {
        communityTreasury = _communityTreasury;
        charity = _charity;
    }

    // Function to start presale
    function changePreSaleStatus(bool _status) external onlyOwner {
        isPreSaleActive = _status;
    }

    // Function to start main sale
    function changeMainSaleStatus(bool _status) external onlyOwner {
        isMainSaleActive = _status;
    }
    
    // Function to reveal all NFTs
    function changeRevealStatus(bool _status) external onlyOwner {
        reveal = _status;
    }
    
    // Function givePresaleAccess to give presale access to addresses
    function givePresaleAccess(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            presaleAccess[_addresses[i]] = true;
        }
    }

    // Function to set giveaway users (tokenIds should be below 200)
    function setGiveawayUsers(address[] memory _to, uint256[] memory _tokenIds) external onlyOwner {
        require(_to.length == _tokenIds.length, "array size mismatch");
        for(uint256 i = 0; i < _to.length; i++) {
            giveaway[_to[i]].push(_tokenIds[i]);
        }
    }
    
    // Function to set Base and Blind URI
    function setURIs(string memory _blindURI, string memory _URI, string memory _reserveURI) external onlyOwner {
        blindURI = _blindURI;
        baseURI = _URI;
        reserveURI = _reserveURI;
    }

    //Function to withdraw collected amount during minting by the owner
    function withdraw(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance should be more than zero");
        payable(_to).transfer(balance);
    }

    // Function to mint new NFTs during the presale
    function mintDuringPresale(uint256 _numOfTokens) public payable whenNotPaused nonReentrant {
        require(isPreSaleActive==true, "Presale Not Active");
        require(presaleAccess[msg.sender] == true, "Presale Access Denied");
        require(presaleClaimed[msg.sender].add(_numOfTokens) <= PRESALE_PURCHASE_LIMIT, 
            "Above Presale Purchase Limit");
        require(publicTotalSupply.add(_numOfTokens) <= PUBLIC_NFT, 'Purchase would exceed max NFTs');
        require(NFT_PRICE.mul(_numOfTokens) == msg.value, "Invalid Amount");

        checkDistribution(_numOfTokens);

        for (uint256 i = 0; i < _numOfTokens; i++) {
            _safeMint(msg.sender, RESERVE_NFT.add(publicTotalSupply));
            publicTotalSupply = publicTotalSupply.add(1);
        }
        presaleClaimed[msg.sender] = presaleClaimed[msg.sender].add(_numOfTokens);
    }

    // Function to mint new NFTs during the public sale
    function mint(uint256 _numOfTokens) public payable whenNotPaused nonReentrant {
        require(isMainSaleActive==true, "Sale Not Active");
        require(mainSaleClaimed[msg.sender].add(_numOfTokens) <= MAINSALE_PURCHASE_LIMIT, 
            "Above Main Sale Purchase Limit");
        require(publicTotalSupply.add(_numOfTokens) <= PUBLIC_NFT, "Purchase would exceed max NFTs");
        require(NFT_PRICE.mul(_numOfTokens) == msg.value, "Invalid Amount");
        
        checkDistribution(_numOfTokens);

        for(uint256 i = 0; i < _numOfTokens; i++) {
            _mint(msg.sender, RESERVE_NFT.add(publicTotalSupply));
            publicTotalSupply = publicTotalSupply.add(1);
        }

        mainSaleClaimed[msg.sender] = mainSaleClaimed[msg.sender].add(_numOfTokens);
    }

    // Function to claim giveaway
    function claimGiveaway() external whenNotPaused nonReentrant {
        for(uint256 i=0; i < giveaway[msg.sender].length; i++) {
            _safeMint(msg.sender, giveaway[msg.sender][i]);
        }
    }

    // Function to mint unclaimed
    function mintUnclaimed(address _to, uint256[] memory _tokenIds) external onlyOwner {
        for(uint256 i=0; i < _tokenIds.length; i++) {
            _safeMint(_to, _tokenIds[i]);
        }
    }
    
    // Function to get token URI of given token ID
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!reveal) {
            return string(abi.encodePacked(blindURI));
        } else {
            if (_tokenId < RESERVE_NFT) {
                return string(abi.encodePacked(reserveURI, _tokenId.toString()));
            } else {
                return string(abi.encodePacked(baseURI, _tokenId.toString()));
            }
        }
    }

    // Function to check charity and treasury distribution
    function checkDistribution(uint256 _numOfTokens) internal {
        if (publicTotalSupply < PUBLIC_NFT &&  publicTotalSupply.add(_numOfTokens) >= PUBLIC_NFT) {
            payable(communityTreasury).transfer(15 ether);
            payable(charity).transfer(12 ether);
        } else if (publicTotalSupply < 3675 && publicTotalSupply.add(_numOfTokens) >= 3675) {
            payable(communityTreasury).transfer(12 ether);
            payable(charity).transfer(8 ether);
        } else if (publicTotalSupply < 2450 &&  publicTotalSupply.add(_numOfTokens) >= 2450) {
            payable(communityTreasury).transfer(8 ether);
            payable(charity).transfer(6 ether);
        } else if (publicTotalSupply < 1225 && publicTotalSupply.add(_numOfTokens) >= 1225) {
            payable(communityTreasury).transfer(5 ether);
            payable(charity).transfer(4 ether);
        }
    }

    // Function to pause 
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause 
    function unpause() external onlyOwner {
        _unpause();
    }
}
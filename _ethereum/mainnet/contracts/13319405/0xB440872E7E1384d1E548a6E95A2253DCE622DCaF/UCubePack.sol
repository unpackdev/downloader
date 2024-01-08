// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./ERC721.sol";
import "./Context.sol";
import "./Ownable.sol";


interface IMintPass {
    function balanceOf(address owner) external view returns (uint256);
}


interface ICubes {
    function mintByPack(address owner) external;
}


contract UCubePack is Context, Ownable, ERC721 ("UCubePack", "UCubePack") {
    event Opened(address indexed from, uint256 indexed tokenId);
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyCollaborator() {
        bool isCollaborator = false;
        for (uint256 i; i < collaborators.length; i++) {
            if (collaborators[i].addr == msg.sender) {
                isCollaborator = true;

                break;
            }
        }

        require(
            owner() == _msgSender() || isCollaborator,
            "Ownable: caller is not the owner nor a collaborator"
        );

        _;
    }

    modifier mintEarlyStarted() {
        require(
            (startEarlyMintDate != 0 && startEarlyMintDate <= block.timestamp),
            "You are too early"
        );

        _;
    }

    
    uint256 private startEarlyMintDate = 1632866400; // 28.09.2021 22:00 UTC
    uint256 private startWhitelistMintDate = 1632949200; // 29.09.2021 21:00 UTC
    uint256 private startRegularMintDate = 1632952800; // 29.09.2021 22:00 UTC

    uint256 private claimPrice = 90000000000000000;

    
    uint256 private totalTokens = 9340;
    uint256 private totalMintedTokens = 0;
    uint256 private totalSupplyNum = 0;
    mapping(uint256 => bool) private openedPacks;

    uint128 private basisPoints = 10000;
    
    uint8 constant maxEarlyClaimsPerWallet = 5;
    uint8 constant maxWhitelistClaimsPerWallet = 1;
    uint8 constant maxRegularClaimsPerWallet = 20;
    
    uint256 constant whitelistMaxSize = 1000;

    mapping(address => uint256) private claimedTokenPerWallet;
    
    mapping(address => uint256[]) private tokensByAddress;
    
    string private baseURI = "https://ucubemeta.com/pack/meta/";
    string private contractBaseURI = "https://ucubemeta.com/pack/contract_meta";
    
    struct Collaborators {
        address addr;
        uint256 cut;
    }
    
    Collaborators[] internal collaborators;
    
    address private mintpassContractAddress;
    address private cubesContractAddress;
    
    mapping(address => bool) private whitelist;
    uint256 private whitelistCurrentSize = 0;
    

    
    // ONLY OWNER

    /**
     * Sets the collaborators of the project with their cuts
     */
    function addCollaborators(Collaborators[] memory _collaborators)
        external
        onlyOwner
    {
        require(collaborators.length == 0, "Collaborators were already set");

        uint128 totalCut;
        for (uint256 i; i < _collaborators.length; i++) {
            collaborators.push(_collaborators[i]);
            totalCut += uint128(_collaborators[i].cut);
        }

        require(totalCut == basisPoints, "Total cut does not add to 100%");
    }
    
    

    function setMintpassAddr(address _addr) external onlyOwner {
       mintpassContractAddress = _addr;
    }
    
    
    function setCubesAddr(address _addr) external onlyOwner {
       cubesContractAddress = _addr;
    }
    
    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    
    function setContractBaseTokenURI(string memory _uri) external onlyOwner {
        contractBaseURI = _uri;
    }

    /**
     * @dev Sets the claim price for each token
     */
    function setClaimPrice(uint256 _claimPrice) external onlyOwner {
        claimPrice = _claimPrice;
    }
    
    function setStartEarlyMintDate(uint256 _startMintDate) external onlyOwner {
        startEarlyMintDate = _startMintDate;
    }
    
    function setStartRegularMintDate(uint256 _startMintDate) external onlyOwner {
        startRegularMintDate = _startMintDate;
    }
    
    function setStartWhitelistMintDate(uint256 _startMintDate) external onlyOwner {
        startWhitelistMintDate = _startMintDate;
    }
    
    function giftPack(uint8 _numOfPacks, address _addresses) external onlyOwner {
        require((totalMintedTokens + _numOfPacks) <= totalTokens, "No packs left to be minted");
        require(_numOfPacks <= 5, "Too much");

        for (uint8 j = 0; j < _numOfPacks; j++) {
            _mint(_addresses, (totalMintedTokens + 1));
            
            tokensByAddress[_addresses].push((totalMintedTokens + 1));
            openedPacks[(totalMintedTokens + 1)] = false;
        
            totalMintedTokens++;
            totalSupplyNum++;
        }
        
        claimedTokenPerWallet[msg.sender] = claimedTokenPerWallet[msg.sender] + _numOfPacks;
    }
    
    // ONLY collaborators
    
    /**
     * @dev Allows to withdraw the Ether in the contract and split it among the collaborators
     */
    function withdraw() external onlyCollaborator {
        uint256 totalBalance = address(this).balance;

        for (uint256 i; i < collaborators.length; i++) {
            payable(collaborators[i].addr).transfer(
                mulScale(totalBalance, collaborators[i].cut, basisPoints)
            );
        }
    }



    function addToWhitelist(address[] calldata _addresses) external onlyCollaborator {
        require(whitelistMaxSize >= (whitelistCurrentSize + _addresses.length), "Whitelist capacity increased");
        
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
        
        whitelistCurrentSize = whitelistCurrentSize + _addresses.length;
    }



    // END ONLY COLLABORATORS


    
    
    fallback() external payable {}
    
    receive() external payable {}
    
    function getAvailableToMint() external view returns (uint256) {
        return (totalTokens - totalMintedTokens);
    }
    
    function mint(uint8 _numOfPacks) external payable callerIsUser mintEarlyStarted {
        require(msg.value >= (claimPrice * _numOfPacks), "Not enough Ether to mint a pack");
        require((totalMintedTokens + _numOfPacks) <= totalTokens, "No packs left to be minted");

        uint8 maxPerVallet = 0;


        if (startRegularMintDate <= block.timestamp) {
            maxPerVallet = maxRegularClaimsPerWallet;
        } else {
            uint256 mintpassNumber = IMintPass(mintpassContractAddress).balanceOf(msg.sender);
            if (0 < mintpassNumber) {
                maxPerVallet = maxEarlyClaimsPerWallet;
            } else {
                if (startWhitelistMintDate <= block.timestamp) {
                    if (whitelist[msg.sender]) {
                        maxPerVallet = maxWhitelistClaimsPerWallet;
                    }
                }
            }
        }
        
        require(0 < maxPerVallet, "You are too early.");
        
        require(
            (claimedTokenPerWallet[msg.sender] + _numOfPacks) <= maxPerVallet,
            "You cannot claim more packs."
        );

        for (uint8 j = 0; j < _numOfPacks; j++) {
            _mint(msg.sender, (totalMintedTokens + 1));
            
            tokensByAddress[msg.sender].push((totalMintedTokens + 1));
            openedPacks[(totalMintedTokens + 1)] = false;
        
            totalMintedTokens++;
            totalSupplyNum++;
        }
        
        claimedTokenPerWallet[msg.sender] = claimedTokenPerWallet[msg.sender] + _numOfPacks;
    }
    
    function contractURI() public view returns (string memory) {
        return contractBaseURI;
    }


    function getTokensByAddress(address _addr) public view returns (uint256[] memory) {
        return tokensByAddress[_addr];
    }
    
    
    function open(uint256 tokenId) external callerIsUser {
        require(
            ownerOf(tokenId) == msg.sender,
            "You can only open your own pack"
        );
        
        require(openedPacks[tokenId] == false, "Pack is already opened");

        openedPacks[tokenId] = true;
        
        ICubes(cubesContractAddress).mintByPack(msg.sender);
        
        _burn(tokenId);
        totalSupplyNum--;

        for (uint16 i = 0; i < tokensByAddress[msg.sender].length; i++) {
            if (tokensByAddress[msg.sender][i] == tokenId) {
                delete tokensByAddress[msg.sender][i];
            }
        }

        emit Opened(msg.sender, tokenId);
    }
    
    function hasOpened(uint256 tokenId) external callerIsUser view returns (bool) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        
        return openedPacks[tokenId];
    } 
    
    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return totalSupplyNum;
    }
    
    
    
    // INTERNAL 
    
    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }
    
    
    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
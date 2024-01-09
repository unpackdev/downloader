// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721Enumerable.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";

interface ISamuraiDoge {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IHONOR {
    function balanceOf(address account) external view returns (uint256);

    function burn(address from, uint256 amount) external;
}

interface IWar {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract SamuraiDoge3D is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    bool public mintIsActive = false;
    bool public onlyWhitelisted = false;
    uint256 public maxToken;
    uint256 public maxTokensPerTransaction;
    uint256 public mintEthPrice;
    uint256 public mintHonorPrice;
    uint256 public claimHonorPrice;
    string private _baseURIextended;
    mapping(address => bool) public whitelist;
    mapping(uint256 => bool) public samuraidogeClaimed;
    ISamuraiDoge samuraidoge;
    IHONOR honor;
    IWar war;

    constructor(
        uint256 _maxToken,
        uint256 _maxTokensPerTransaction,
        uint256 _mintEthPrice,
        uint256 _mintHonorPrice,
        uint256 _claimHonorPrice,
        address _samuraidoge,
        address _honor,
        address _war
    ) ERC721("SamuraiDoge3D", "SD3D") {
        maxToken = _maxToken;
        maxTokensPerTransaction = _maxTokensPerTransaction;
        mintEthPrice = _mintEthPrice;
        mintHonorPrice = _mintHonorPrice;
        claimHonorPrice = _claimHonorPrice;
        samuraidoge = ISamuraiDoge(_samuraidoge);
        honor = IHONOR(_honor);
        war = IWar(_war);
    }

    function addAddressesToWhitelist(address[] memory _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            whitelist[_addrs[i]] = true;
        }
    }

    function removeAddressesFromWhitelist(address[] memory _addrs)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            whitelist[_addrs[i]] = false;
        }
    }

    function setWhitelistStatus(bool _status) public onlyOwner {
        onlyWhitelisted = _status;
    }

    function setMintStatus(bool _status) public onlyOwner {
        mintIsActive = _status;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _baseURIextended = _baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setMaxToken(uint256 numberOfTokens) external onlyOwner {
        maxToken = numberOfTokens;
    }

    function setMaxTokensPerTransaction(uint256 numberOfTokens)
        external
        onlyOwner
    {
        maxTokensPerTransaction = numberOfTokens;
    }

    function setMintEthPrice(uint256 _mintEthPrice) external onlyOwner {
        mintEthPrice = _mintEthPrice;
    }

    function setMintHonorPrice(uint256 _mintHonorPrice) external onlyOwner {
        mintHonorPrice = _mintHonorPrice;
    }

    function setClaimHonorPrice(uint256 _claimHonorPrice) external onlyOwner {
        claimHonorPrice = _claimHonorPrice;
    }

    function _isOwner(uint256 tokenId, address account)
        internal
        view
        returns (bool)
    {
        if (samuraidoge.ownerOf(tokenId) == account) {
            return true;
        } else if (war.ownerOf(tokenId) == account) {
            return true;
        } else {
            return false;
        }
    }

    function claimUsingSamuraiDoge(uint16[] calldata sdTokenIds) public {
        // Can only mint when claimIsActive
        require(mintIsActive, "Minting is not available yet");
        // Check whitelist requirement
        if (onlyWhitelisted) {
            require(
                whitelist[msg.sender],
                "Minting is only available for whitelisted users"
            );
        }
        // Check number of tokens requested per transaction
        uint256 numberOfTokens = sdTokenIds.length / 2;
        require(
            numberOfTokens <= maxTokensPerTransaction,
            "Number of tokens requested exceeded the value allowed per transaction"
        );
        // Check token availability
        require(
            totalSupply() + numberOfTokens <= maxToken,
            "Purchase would exceed max supply of 3D SamuraiDoge tokens"
        );
        // Check $HON balance
        require(
            honor.balanceOf(msg.sender) >= claimHonorPrice * numberOfTokens,
            "Not enough HONOR balance in this address"
        );
        // Check token ownership and claim status
        for (uint256 i = 0; i < numberOfTokens * 2; i++) {
            require(
                !samuraidogeClaimed[sdTokenIds[i]],
                "Free token already claimed by this SamuraiDoge token"
            );
            require(
                _isOwner(sdTokenIds[i], msg.sender),
                "Only the owner of this SamuraiDoge token can call this function"
            );
            samuraidogeClaimed[sdTokenIds[i]] = true;
        }
        // Mint
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
        // Burn $HON
        honor.burn(msg.sender, claimHonorPrice * numberOfTokens);
    }

    function mintUsingHonor(uint256 numberOfTokens) public {
        // Check mintIsActive
        require(mintIsActive, "Minting is not available yet");
        // Check whitelist requirement
        if (onlyWhitelisted) {
            require(
                whitelist[msg.sender],
                "Minting is only available for whitelisted users"
            );
        }
        // Check number of tokens requested per transaction
        require(
            numberOfTokens <= maxTokensPerTransaction,
            "Number of tokens requested exceeded the value allowed per transaction"
        );
        // Check token availability
        require(
            totalSupply() + numberOfTokens <= maxToken,
            "Purchase would exceed max supply of 3D SamuraiDoge tokens"
        );
        // Check $HON balance
        require(
            honor.balanceOf(msg.sender) >= mintHonorPrice * numberOfTokens,
            "Not enough HONOR balance in this address"
        );
        // Mint
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
        // Burn $HON
        honor.burn(msg.sender, mintHonorPrice * numberOfTokens);
    }

    function mint(uint256 numberOfTokens) public payable {
        // Check mintIsActive
        require(mintIsActive, "Minting is not available yet");
        // Check whitelist requirement
        if (onlyWhitelisted) {
            require(
                whitelist[msg.sender],
                "Minting is only available for whitelisted users"
            );
        }
        // Check number of tokens requested per transaction
        require(
            numberOfTokens <= maxTokensPerTransaction,
            "Number of tokens requested exceeded the value allowed per transaction"
        );
        // Check token availability
        require(
            totalSupply() + numberOfTokens <= maxToken,
            "Purchase would exceed max supply of 3D SamuraiDoge tokens"
        );
        // Check ether value == price;
        require(
            numberOfTokens * mintEthPrice == msg.value,
            "Ether value sent is not correct"
        );
        // Mint
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function reserveTokens(uint256 amount) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        uint256 balance;
        if ((maxToken - supply) >= amount) {
            balance = amount;
        } else {
            balance = maxToken - supply;
        }

        for (i = 0; i < balance; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

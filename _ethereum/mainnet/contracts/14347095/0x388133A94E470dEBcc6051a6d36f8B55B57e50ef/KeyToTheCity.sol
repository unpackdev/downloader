// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./Whitelist.sol";
import "./IKeyClaimable.sol";
import "./IBrainsDistributor.sol";

contract KeyToTheCity is Ownable, Pausable, ERC721Enumerable, Whitelist {

    struct KeyClaim {
        bool cityClaimed;
        bool pixelClaimed;
        bool threeDClaimed;
        bool humanClaimed;
        bool brainsClaimed;
    }

    string private baseURI;

    IERC20 public brains;
    IERC721 public zombies;
    IKeyClaimable public cities;
    IKeyClaimable public humans;
    IKeyClaimable public pixels;
    IKeyClaimable public threeD;

    IBrainsDistributor public distributor;

    mapping(address => uint8) public whitelistMintedKeys;
    mapping(uint256 => KeyClaim) public keyClaims;
    mapping(address => bool) public holderWhitelistClaims;

    bool public publicSaleActive;
    bool public holderWhitelistActive;
    bool public pixelsClaimable;
    bool public threeDClaimable;

    uint256 public mintPrice;
    uint256 public maxBrainsPerKey = 10000;

    uint256 public constant MAX_KEYS = 10000;

    constructor(address genesis) ERC721("Zombie Frens Key to the City", "ZFKEY") {
        zombies = IERC721(genesis);
        mintPrice = 0.035 ether;
        holderWhitelistActive = true;
    }

    function init(address _distributor, address _cities, address _humans, address _brains) external onlyOwner {
        distributor = IBrainsDistributor(_distributor);
        cities = IKeyClaimable(_cities);
        humans = IKeyClaimable(_humans);
        brains = IERC20(_brains);
    }

    function claimMany(uint256[] calldata tokenIds) external whenNotPaused {
        for(uint256 i=0;i<tokenIds.length;++i) {
            claim(tokenIds[i]);
        }
    }

    function claim(uint256 tokenId) public whenNotPaused ownsKey(tokenId) {
        if(keyClaims[tokenId].cityClaimed && keyClaims[tokenId].humanClaimed && keyClaims[tokenId].brainsClaimed) {
            revert("key_already_claimed");
        }
        require(address(cities) != address(0x0), "cities_address_not_defined");
        require(address(humans) != address(0x0), "humans_address_not_defined");
        require(address(brains) != address(0x0), "brains_address_not_defined");
        if(!keyClaims[tokenId].cityClaimed && isInPercentile(tokenId, 30)) {
            keyClaims[tokenId].cityClaimed = true;
            cities.claimKeyFor(msg.sender);
        } else {
            keyClaims[tokenId].cityClaimed = true;
        }
        if(!keyClaims[tokenId].humanClaimed) {
            if(isInPercentile(tokenId, 10)) {
                keyClaims[tokenId].humanClaimed = true;
                humans.claimKeyFor(msg.sender);
            } else {
                keyClaims[tokenId].humanClaimed = true;
            }
        }
        if(!keyClaims[tokenId].brainsClaimed) {
            uint256 brainsAmount = random(tokenId) % maxBrainsPerKey;
            if(brainsAmount > distributor.remainingBrains()) {
                brainsAmount = distributor.remainingBrains();
            } 
            keyClaims[tokenId].brainsClaimed = true;
            if(brainsAmount == 0) return;
            distributor.mintBrainsFor(msg.sender, brainsAmount);
        }
    }

    function set3DClaimable(address _threeD) external onlyOwner {
        threeDClaimable = true;
        threeD = IKeyClaimable(_threeD);
    }

    function setPixelClaimable(address _pixel) external onlyOwner {
        pixelsClaimable = true;
        pixels = IKeyClaimable(_pixel);
    }

    function claim3D(uint256 tokenId) external whenNotPaused ownsKey(tokenId) {
        require(threeDClaimable, "3d_not_claimable");
        require(address(threeD) != address(0x0), "address_not_defined");
        require(!keyClaims[tokenId].threeDClaimed, "3D_already_claimed");
        keyClaims[tokenId].threeDClaimed = true;
        threeD.claimKeyFor(msg.sender);
    }

    function claimPixel(uint256 tokenId) external whenNotPaused ownsKey(tokenId) {
        require(pixelsClaimable, "pixel_not_claimable");
        require(address(pixels) != address(0x0), "address_not_defined");
        require(!keyClaims[tokenId].pixelClaimed, "pixel_already_claimed");
        keyClaims[tokenId].pixelClaimed = true;
        pixels.claimKeyFor(msg.sender);
    }

    function mint(bytes32[] calldata merkleProof, uint8 amount) external payable whenNotPaused {
        require(amount > 0, "amount_zero");
        require(totalSupply() + amount <= MAX_KEYS, "max_keys_minted");
        require(holderWhitelistActive || whitelistActive || publicSaleActive, "no_active_sale");
        if(!whitelistActive) {
            require(msg.value >= getMintCost(amount), "not_enough_ether");
        }
        if(holderWhitelistActive) {
            claimHolderWhitelist(amount);
        } else if(whitelistActive) {
            claimWhitelist(merkleProof);
        } else if(publicSaleActive) {
            for(uint256 i=0;i<amount;++i) {
                _safeMint(msg.sender, totalSupply());
            }
        }
    }

    function mintFor(address to, uint8 amount) external onlyOwner {
        for(uint256 i=0;i<amount;++i) {
            _safeMint(to, totalSupply());
        }
    }

    function updateWhitelistMerkle(bytes32 merkleRoot_) external onlyOwner {
        require(merkleRoot_ != 0x0, "invalid_merkle_root");
        bytes32 currentRoot = _merkleRoot;
        _merkleRoot = merkleRoot_;

        emit WhitelistMerkleRootUpdated(currentRoot, _merkleRoot);
    }

    function claimWhitelist(bytes32[] calldata merkleProof) internal whenNotPaused _canMintWhitelist(merkleProof) {
        require(!holderWhitelistClaims[msg.sender], "already_claimed");
        _safeMint(msg.sender, totalSupply());
        holderWhitelistClaims[msg.sender] = true;
    }

    function claimHolderWhitelist(uint8 amount) internal whenNotPaused {
        uint256 owned = totalOwned();
        uint256 claimed = whitelistMintedKeys[msg.sender];
        require(claimed + amount <= owned, "exceeds_owned_zombies");
        uint256 tokenId = totalSupply();
        for(uint256 i=0;i<amount;++i) {
            _safeMint(msg.sender, tokenId + i);
            whitelistMintedKeys[msg.sender] += 1;
        }
    }

    function setWhitelistSale() external onlyOwner {
        holderWhitelistActive = false;
        publicSaleActive = false;
        whitelistActive =  true;
    }

    function setPublicSale(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
        whitelistActive =  false;
        holderWhitelistActive = false;
        publicSaleActive = true;
    }

    function setHolderWhitelistActive() external onlyOwner {
        require(!holderWhitelistActive, "whitelist_active");
        publicSaleActive = false;
        whitelistActive = false;
        holderWhitelistActive = true;
    }

    function flipPublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function updateDistributor(address _distributor) external onlyOwner {
        distributor = IBrainsDistributor(_distributor);
    }

    function updateMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function isInPercentile(uint256 tokenId, uint16 percentile) internal view returns (bool inPercentile) {
        uint256 thirtyPercent = type(uint16).max / 100 * percentile;
        return (uint16(random(tokenId)) < thirtyPercent);
    }

    function random(uint256 tokenId) internal view returns (uint256 number) {
        number = uint256(keccak256(abi.encodePacked(block.timestamp, block.coinbase, block.difficulty, msg.sender, tokenId)));
    }

    function getMintCost(uint256 amount) internal view returns (uint256 cost) {
        cost = amount * mintPrice;
    }

    function totalOwned() internal view returns (uint256 balance) {
        balance = zombies.balanceOf(msg.sender);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        require(_owner != address(0), "owner_zero_address");
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount <= 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    modifier ownsKey(uint256 tokenId) {
        require(totalSupply() >= tokenId, "token_does_not_exist");
        require(ownerOf(tokenId) == msg.sender, "caller_does_not_own");
        _;
    }
}
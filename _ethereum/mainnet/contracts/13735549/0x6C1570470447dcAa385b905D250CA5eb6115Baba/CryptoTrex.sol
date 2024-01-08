//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ERC721.sol";
import "./IERC1155.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./Fossil.sol";

contract CryptoTrex is ERC721Upgradeable, OwnableUpgradeable {
	address private constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    IERC1155 private originContract;
    Fossil private tokenContract;

    string internal _contractURI; // unused
    string internal _tokenURI;

    bool internal _stakingIsActive;
    mapping(uint256 => uint256) private _stakeSince;
    uint256 private _stakingOriginalBeginTime;

    function initialize(
        address _v1contract,
        address _tokenContract
    ) public initializer {
        __ERC721_init("CryptoTrex", "TREX");
        __Ownable_init();
        originContract = IERC1155(_v1contract);
        tokenContract = Fossil(_tokenContract);
        _mint(msg.sender, 96909460163064550845444608935305903013667688084848214180379906743688249737217); // #1108 dbz
        _mint(msg.sender, 96909460163064550845444608935305903013667688084848214180379906744787761364993); // #1109 mecha
        _mint(msg.sender, 96909460163064550845444608935305903013667688084848214180379906745887272992769); // #1110 stock
        _mint(msg.sender, 96909460163064550845444608935305903013667688084848214180379906746986784620545); // #1111 cosmic
    }
    
    function migrate(uint256 _tokenId) external {
        require(isValidRex(_tokenId), "CryptoTrex: invalid token");
        require(originContract.balanceOf(msg.sender, _tokenId) > 0, "CryptoTrex: not an owner");
        tokenContract.mint(msg.sender, 10 ether);
        _mint(msg.sender, _tokenId);
        originContract.safeTransferFrom(msg.sender, BURN_ADDRESS, _tokenId, 1, "");
    }
    
    function migrateBatch(uint256[] calldata _tokenIds) external {
        require(_tokenIds.length < 50, "CryptoTrex: too many to handle");
        require(_tokenIds.length > 0, "CryptoTrex: nothing to migrate");
        uint256[] memory amounts = new uint256[](_tokenIds.length);
        for (uint i=0; i<_tokenIds.length; i++) {
            require(isValidRex(_tokenIds[i]), "CryptoTrex: invalid token");
            require(originContract.balanceOf(msg.sender, _tokenIds[i]) > 0, "CryptoTrex: not an owner");
            amounts[i]=1;
            _mint(msg.sender, _tokenIds[i]);
        }
        tokenContract.mint(msg.sender, _tokenIds.length * 10 ether);
        originContract.safeBatchTransferFrom(msg.sender, BURN_ADDRESS, _tokenIds, amounts, "");
    }

    // Staking
    function setStakingStatus(bool value) external onlyOwner {
        _stakingIsActive = value;
    }

    function setStakingStartTimestamp() external onlyOwner {
        _stakingOriginalBeginTime = block.timestamp;
    }

    function rewards(uint256[] calldata _tokenIds) external view returns (uint256) {
        require(_stakingIsActive, "CryptoTrex: staking not active");
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if(_exists(_tokenIds[i])) {
                totalRewards += _currentRewards(_tokenIds[i]);
            }
        }
        return totalRewards;
    }

    function claim(uint256[] calldata _tokenIds) external {
        require(_stakingIsActive, "CryptoTrex: staking not active");
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if(_exists(_tokenIds[i])) {
                require(ownerOf(_tokenIds[i]) == msg.sender, "CryptoTrex: not owned");
                totalRewards += _currentRewards(_tokenIds[i]);
                _stakeSince[_tokenIds[i]] = block.timestamp;
            }
        }
        require(totalRewards > 0, "CryptoTrex: nothing to claim");
        tokenContract.mint(msg.sender, totalRewards);
    }

    function _currentRewards(uint256 tokenId) internal view returns (uint256) {
        uint256 since = _stakeSince[tokenId];
        if (since == 0) {
            since = _stakingOriginalBeginTime;
        }
        return ((block.timestamp - since) * 1 ether) / (1 days / 3);
    }

    /*
        Etherscan functions
    */
    function totalSupply() external pure returns (uint256) {
        return 1111;
    }

    /*
        Opensea functions
    */
    function setTokenURI(string calldata _uri) external onlyOwner {
        _tokenURI = _uri;
    }
    function baseTokenURI() external view returns (string memory) {
        return _tokenURI;
    }
    
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(
            _tokenURI,
            Strings.toString(_tokenId),
            ".json"
        ));
    }

    /* 
        Utility functions
     */
    function isValidRex(uint256 _tokenId) internal pure returns(bool){
        if (_tokenId >> 96 != 0x000000000000000000000000D640CF88F763CEE6B243F1CAB3D0BEFDAFC47B9E){
            return false;
        }
		if (_tokenId & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1){
			return false;
        }
		uint256 id = (_tokenId & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		if (id > 1172 || id < 59 || id == 163 || id == 166 || id == 265 || id == 669 || id == 670 || id == 671 || id == 672){
			return false;
        }
		return true;
    }
}

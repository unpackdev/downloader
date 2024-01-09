// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";

contract RichMeka is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    event Staked(address indexed owner, uint256 indexed tokenId);
    event Unstaked(address indexed owner, uint256 indexed tokenId, uint256 reward);
    event Claimed(address indexed owner, uint256 indexed tokenId, uint256 amount);

    struct Stake {
        bool created;
        uint256 createdAt;
        uint256 rate;
        uint256 claimedAmount;
    }

    bool public _saleIsActive;
    string public _baseTokenURI;
    address private _serumAccount;
    IERC20 private _serumContract;
    uint256 _tokenIdTracker;
    uint256 _reservedTokenIdTracker;
    uint256 public _maxSupply;
    uint256 public _maxNumberOfTokens;
    uint256 public _tokensInReserve;
    uint256 public _tokenPrice;
    uint256 public _commissionValue;
    uint256 public _minClaim;
    uint256 public _coloredMekaRate;
    uint256 public _monochromeMekaRate;
    uint256 public _minStakeTime;
    uint256 public _stakedTokensCount;
    mapping(address => mapping(uint256 => Stake)) private _holderStakes;
    mapping(address => uint256[]) private _holderTokensStaked;

    function initialize() public initializer {
        _baseTokenURI = "https://api.richmeka.com/metadata/richmeka/";
        _tokenIdTracker = 60; // _tokensInReserve
        _maxSupply = 888;
        _maxNumberOfTokens = 10;
        _tokensInReserve = 60;
        _tokenPrice = 0.055 ether;
        _commissionValue = 0.005 ether;
        _minClaim = 500000000000000000000; // 500 SERUM;
        _coloredMekaRate = 8000000000000000000000; // 8 000 SERUM;
        _monochromeMekaRate = 5000000000000000000000; // 5 000 SERUM;
        _minStakeTime = 86400; // 24 hours;
        __ERC721_init("RichMeka", "RM");
        __Ownable_init();
        _restoreState();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function flipSaleState() external onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        _maxSupply = maxSupply;
    }

    function setTokenPrice(uint256 tokenPrice) external onlyOwner {
        _tokenPrice = tokenPrice;
    }

    function setCommissionValue(uint256 commissionValue) external onlyOwner {
        _commissionValue = commissionValue;
    }

    function setSerumContract(address serumContract) external onlyOwner {
        _serumContract = IERC20(serumContract);
    }

    function setSerumAccount(address serumAccount) external onlyOwner {
        _serumAccount = serumAccount;
    }

    function setMinStakeTime(uint256 time) external onlyOwner {
        _minStakeTime = time;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _stake(uint256 tokenId) internal {
        require(!_holderStakes[msg.sender][tokenId].created, "RichMeka: staking of token that is already staked");

        _holderStakes[msg.sender][tokenId] = Stake(true, block.timestamp, tokenId <= 888 ? _coloredMekaRate : _monochromeMekaRate, 0);
        _holderTokensStaked[msg.sender].push(tokenId);
        _stakedTokensCount += 1;

        emit Staked(msg.sender, tokenId);
    }

    function _unstake(uint256 tokenId) internal {
        require(_holderStakes[msg.sender][tokenId].created, "RichMeka: unstaking of token that is not staked");
        require((block.timestamp - _holderStakes[msg.sender][tokenId].createdAt) >= _minStakeTime, "RichMeka: unstaking of token that is staked for less then min time");

        uint256 reward = ((_holderStakes[msg.sender][tokenId].rate / 86400) * (block.timestamp - _holderStakes[msg.sender][tokenId].createdAt)) - _holderStakes[msg.sender][tokenId].claimedAmount;
        _serumContract.transferFrom(_serumAccount, msg.sender, reward);
        _stakedTokensCount -= 1;

        delete _holderStakes[msg.sender][tokenId];
        for (uint256 i = 0; i < _holderTokensStaked[msg.sender].length; i++) {
            if (_holderTokensStaked[msg.sender][i] == tokenId) {
                 _holderTokensStaked[msg.sender][i] = _holderTokensStaked[msg.sender][_holderTokensStaked[msg.sender].length - 1];
                 _holderTokensStaked[msg.sender].pop();
                 break;
            }
        }

        emit Unstaked(msg.sender, tokenId, reward);
    }

    function mintMekas(uint256 numberOfTokens, bool stakeTokens) external payable {
        require(_saleIsActive, "RichMeka: sale must be active to mint Meka");
        require(numberOfTokens <= _maxNumberOfTokens, "RichMeka: can`t mint more then _maxNumberOfTokens at a time");
        require(msg.value >= numberOfTokens * _tokenPrice, "RichMeka: ether value sent is not correct");
        require(totalSupply() + _tokensInReserve + numberOfTokens <= _maxSupply, "RichMeka: purchase would exceed max supply of Mekas");

        if (totalSupply() + _tokensInReserve + numberOfTokens == _maxSupply) {
            _saleIsActive = false;
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdTracker++;

            if (stakeTokens) {
                _stake(_tokenIdTracker);
            }
            else {
                _mint(msg.sender, _tokenIdTracker);
            }
        }
    }

    function stakeMekas(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "RichMeka: staking of token that is not own");
            _stake(tokenId);
            _burn(tokenId);
        }
    }

    function unstakeMekas(uint256[] memory tokenIds) external payable {
        require(msg.value >= _commissionValue, "RichMeka: ether value sent is not correct");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _unstake(tokenId);
            _mint(msg.sender, tokenId);
        }
    }

    function claimSerum(uint256 tokenId, uint256 amount) external payable {
        require(msg.value >= _commissionValue, "RichMeka: ether value sent is not correct");
        require(_holderStakes[msg.sender][tokenId].created, "RichMeka: claim of reward for token that is not staked");
        require((block.timestamp - _holderStakes[msg.sender][tokenId].createdAt) >= _minStakeTime, "RichMeka: claim of token that is staked for less then min time");
        require(amount >= _minClaim, "RichMeka: claim amount is less the min amout");

        uint256 reward = ((_holderStakes[msg.sender][tokenId].rate / 86400) * (block.timestamp - _holderStakes[msg.sender][tokenId].createdAt)) - _holderStakes[msg.sender][tokenId].claimedAmount;
        require(amount <= reward, "RichMeka: reward is less then amount");

        _holderStakes[msg.sender][tokenId].claimedAmount += amount;
        _serumContract.transferFrom(_serumAccount, msg.sender, amount);

        emit Claimed(msg.sender, tokenId, amount);
    }

    function claimSerumAll() external payable {
        require(msg.value >= _commissionValue, "RichMeka: ether value sent is not correct");

        for (uint256 i = 0; i < _holderTokensStaked[msg.sender].length; i++) {
            uint256 tokenId = _holderTokensStaked[msg.sender][i];
            uint256 amount = ((_holderStakes[msg.sender][tokenId].rate / 86400) * (block.timestamp - _holderStakes[msg.sender][tokenId].createdAt)) - _holderStakes[msg.sender][tokenId].claimedAmount;

            if (amount >= _minClaim && (block.timestamp - _holderStakes[msg.sender][tokenId].createdAt) >= _minStakeTime) {
                _holderStakes[msg.sender][tokenId].claimedAmount += amount;
                _serumContract.transferFrom(_serumAccount, msg.sender, amount);

                emit Claimed(msg.sender, tokenId, amount);
            }
        }
    }

    function getTokensOfHolder(address holder) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(holder);
        if (tokenCount == 0) {
            return new uint256[](0);
        }
        else {
            uint256[] memory tokens = new uint256[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++) {
                tokens[i] = tokenOfOwnerByIndex(holder, i);
            }
            return tokens;
        }
    }

    function getStakedTokensOfHolder(address holder) external view returns (uint256[] memory) {
        return _holderTokensStaked[holder];
    }

    function getStakeOfHolderByTokenId(address holder, uint256 tokenId) external view returns (uint256, uint256) {
        require(_holderStakes[holder][tokenId].created, "RichMeka: operator query for nonexistent stake");
        return (_holderStakes[holder][tokenId].createdAt, _holderStakes[holder][tokenId].claimedAmount);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply() + _stakedTokensCount;
    }

    function mintFreeMekas(uint256 numberOfTokens, address to) external onlyOwner {
        require(numberOfTokens + _reservedTokenIdTracker <= _tokensInReserve, "RichMeka: purchase would exceed max supply of reserved Mekas");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _reservedTokenIdTracker++;
            _mint(to, _reservedTokenIdTracker);
        }
    }

    function _restoreState() internal {
        _reservedTokenIdTracker = 20;
        _stakedTokensCount = 16;

        _mint(0x830F79Bf3a95Ab5033A2523b3eeE648028b8287e, 1);
        _mint(0x830F79Bf3a95Ab5033A2523b3eeE648028b8287e, 4);
        _mint(0x830F79Bf3a95Ab5033A2523b3eeE648028b8287e, 5);
        _mint(0x830F79Bf3a95Ab5033A2523b3eeE648028b8287e, 10);

        _holderStakes[0x830F79Bf3a95Ab5033A2523b3eeE648028b8287e][2] = Stake(true, 1640721982, _coloredMekaRate, 52594097222222221885620);
        _holderStakes[0x62F1023d2b96d8B4290b02050747B8A8D25012D1][3] = Stake(true, 1640731444, _coloredMekaRate, 0);
        _holderStakes[0xa08848cA401C929556fd8C41220aA770D85BE513][6] = Stake(true, 1641475555, _coloredMekaRate, 0);
        _holderStakes[0xa08848cA401C929556fd8C41220aA770D85BE513][7] = Stake(true, 1640779032, _coloredMekaRate, 0);
        _holderStakes[0xa08848cA401C929556fd8C41220aA770D85BE513][8] = Stake(true, 1640779032, _coloredMekaRate, 0);
        _holderStakes[0x6d57AF94fbc500F1da66DA43197F800E244cec47][9] = Stake(true, 1640850875, _coloredMekaRate, 0);
        _holderStakes[0x04310DB1362EEe131f8602d2c12F47480d84638d][11] = Stake(true, 1641026802, _coloredMekaRate, 0);
        _holderStakes[0x04310DB1362EEe131f8602d2c12F47480d84638d][12] = Stake(true, 1641026802, _coloredMekaRate, 0);
        _holderStakes[0x04310DB1362EEe131f8602d2c12F47480d84638d][13] = Stake(true, 1641026802, _coloredMekaRate, 0);
        _holderStakes[0x5c63D79b97EBb3EC61c48B7c7fedFfC45c7d2717][14] = Stake(true, 1641058059, _coloredMekaRate, 31672511574074073871370);
        _holderStakes[0x2E6ba5DE691D92a36C880D8C101CEb07bAfbE6A4][15] = Stake(true, 1641113651, _coloredMekaRate, 0);
        _holderStakes[0xbAd2C521c8705546A4Ec64166b8B7c559A5326C1][16] = Stake(true, 1641372817, _coloredMekaRate, 0);
        _holderStakes[0xbAd2C521c8705546A4Ec64166b8B7c559A5326C1][17] = Stake(true, 1641372817, _coloredMekaRate, 0);
        _holderStakes[0xbAd2C521c8705546A4Ec64166b8B7c559A5326C1][18] = Stake(true, 1641372817, _coloredMekaRate, 0);
        _holderStakes[0xbAd2C521c8705546A4Ec64166b8B7c559A5326C1][19] = Stake(true, 1641372817, _coloredMekaRate, 0);
        _holderStakes[0xbAd2C521c8705546A4Ec64166b8B7c559A5326C1][20] = Stake(true, 1641372817, _coloredMekaRate, 0);
    }
}
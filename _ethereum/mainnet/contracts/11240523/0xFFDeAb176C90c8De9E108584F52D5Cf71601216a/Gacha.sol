pragma solidity ^0.6.0;

import "./IERC721Enumerable.sol";
import "./hotpotinterface.sol";
import "./IInvite.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";


contract Gacha is Ownable, ReentrancyGuard, Pausable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IHotPot public hotpot;
    IERC721Enumerable public erc721;
    IERC20 public erc20;
    IInvite public invite;

    address public rewardAddress;

    uint256 public price = 1;

    uint8 constant gradeNormal = 1;

    uint8 constant gradeVIP = 2;

    uint8 constant gradeVVIP = 3;

    uint8 constant discount10Pull = 95;

    uint8 constant posibilityDevide = 4;

    uint256 public initPosibility = 8;

    uint256 constant MAX_NFT = 1000;

    string public baseURI = "";

    uint256 internal randomSeed = 1;

    event GachaTicket(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint8 indexed _grade
    );

    event GachaNothing(address indexed _owner);

    modifier ensurePull(uint256 _price) {
        // check balance
        require(
            erc20.balanceOf(msg.sender) >= _price,
            "Wallet balance is not enough!"
        );
        _;
    }

    /**
        ensure NFT amount is less than 1000
     */
    modifier checkNFTCount() {
        require(
            erc721.totalSupply() <= MAX_NFT,
            "Cannot create more NFT any more!"
        );
        _;
    }

    function setRewardAddress(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        rewardAddress = _addr;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setHotPotNFT(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");

        hotpot = IHotPot(_addr);
        erc721 = IERC721Enumerable(_addr);
    }

    function setHotPot(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        erc20 = IERC20(_addr);
    }

    function setInvite(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        invite = IInvite(_addr);
    }

    constructor(
        uint256 _price,
        uint256 _posibility,
        address _reward,
        address _nft,
        address _hotpot,
        address _invite
    ) public {
        initPosibility = _posibility;
        price = _price;

        require(_reward != address(0));
        require(_nft != address(0));
        require(_hotpot != address(0));
        require(_nft.isContract(), "It's not contract address!");
        require(_reward.isContract(), "It's not contract address!");
        require(_hotpot.isContract(), "It's not contract address!");
        require(_invite.isContract(), "It's not contract address!");

        erc20 = IERC20(_hotpot);
        hotpot = IHotPot(_nft);
        erc721 = IERC721Enumerable(_nft);
        invite  = IInvite(_invite);
        rewardAddress = _reward;
    }

    /**
        1 pull
     */
    function pull() external ensurePull(price) nonReentrant whenNotPaused{
        bool res = _pull();
        if (!res) {
            emit GachaNothing(msg.sender);
        }
        //1. get token first
        erc20.safeTransferFrom(msg.sender, rewardAddress, price);

        invite.validCode(msg.sender);
        invite.generateCode(msg.sender);
    }

    /**
        10 pulls
     */

    function pull10()
        external
        ensurePull(price.mul(10).mul(discount10Pull).div(100))
        nonReentrant
        whenNotPaused
    {
        bool gacha = false;
        for (uint256 i = 0; i < 10; i++) {
            bool res = _pull();
            if (res) {
                gacha = true;
            }
        }
        if (!gacha) {
            emit GachaNothing(msg.sender);
        }
        //1. get token first
        erc20.safeTransferFrom(
            msg.sender,
            rewardAddress,
            price.mul(10).mul(discount10Pull).div(100)
        );
        
        invite.validCode(msg.sender);
        invite.generateCode(msg.sender);
    }

    function getPosibilityNow() external view returns (uint256) {
        //1.check the nft amount
        uint256 count = erc721.totalSupply();
        // emit GachaStart(count);
        uint256 posibility = initPosibility;
        if (count < 11) {
            posibility = initPosibility; //8
        } else if (count < 21) {
            posibility = initPosibility * 2; //16
        } else if (count < 51) {
            posibility = initPosibility * 4; //32
        } else if (count < 101) {
            posibility = initPosibility * 8; //64
        } else if (count < 201) {
            posibility = initPosibility * 16; //128
        } else if (count < 501) {
            posibility = initPosibility * 32; //256
        } else {
            posibility = initPosibility * 64; //512
        }
        return posibility;
    }

    /**
        trigger 1 pull
     */
    function _pull() internal checkNFTCount returns (bool) {
        uint256 posibility = this.getPosibilityNow();

        randomSeed += 2;
        //generate random number
        //it is not that safe
        uint256 random = uint256(
            sha256(abi.encodePacked(now, randomSeed, msg.sender))
        ) % (posibility * posibilityDevide * posibilityDevide);

        // emit GachaRandom(random);

        if (random < posibilityDevide * posibilityDevide) {
            if (random == 1) {
                //generate grade 3
                _generateNFT(gradeVVIP);
            } else if (random < posibilityDevide + 1 && random != 0) {
                //generate grade 2
                _generateNFT(gradeVIP);
            } else {
                //generate grade 1
                _generateNFT(gradeNormal);
            }
            return true;
        } else {
            return false;
        }
    }

    function _generateNFT(uint8 _grade) internal {
        uint256 count = erc721.totalSupply();
        uint256 tokenId = count + 1;
        hotpot.mint(msg.sender, tokenId, _grade, baseURI);
        emit GachaTicket(msg.sender, tokenId, _grade);
    }

    function pause() external onlyOwner{
        _pause();
    }

    function unpause() external onlyOwner{
        _unpause();
    }
}

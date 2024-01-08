// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./PausableUpgradeable.sol";
import "./SafeMath32.sol";
import "./SafeMath64.sol";
import "./ManagerUpgradeable.sol";
import "./IMemberController.sol";
import "./IMysteryNFT.sol";
import "./IMysteryNFT_S.sol";


contract BlindBox is ManagerUpgradeable, PausableUpgradeable, IMysteryNFT_S {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using SafeMath32 for uint32;
    using SafeERC20 for IERC20;
    struct SellTime {
        uint64 startTime;
        uint64 endTime;
    }
    IMemberController public mc;
    IMysteryNFT public mysteryNFT;
    SellTime public sellTime;
    uint public price;
    uint public blindBoxLeft;
    uint32[] public saleNumLeft;
    uint32[] public accelerateCardLeft;
    uint32[] public accelerateCardAmount;
    uint32[] public accelerateCardPercent;
    uint32[] public etfTokenCardLeft;
    uint32[] public etfTokenCardAmount;
    uint32[] public governTokenCardLeft;
    uint32[] public governTokenCardAmount;
    mapping(uint => string[]) public tokenURIs;
    mapping(address => bool) public supportFundToken;
    modifier confirmSellTime() {
        uint64 t = uint64(block.timestamp);
        require(msg.sender == tx.origin);
        require(t >= sellTime.startTime && t <= sellTime.endTime, "Inactive time");
        _;
    }

    function initialize(
        address _mc,
        uint64 _startTime,
        uint64 _endTime,
        uint _price) public initializer {
        ManagerUpgradeable.__Manager_init();
        PausableUpgradeable.__Pausable_init();
        mc = IMemberController(_mc);
        mysteryNFT = IMysteryNFT(mc.getMember("MysteryNFT"));
        sellTime.startTime = _startTime;
        sellTime.endTime = _endTime;
        price = _price;
        blindBoxLeft = 200;
        saleNumLeft = [53, 42, 64, 29, 12];
        accelerateCardLeft = [30, 12, 7, 3, 1];
        accelerateCardAmount = [1000, 5000, 10000, 20000, 40000];
        accelerateCardPercent = [30, 70, 100, 200, 400];
        etfTokenCardLeft = [20, 12, 6, 3, 1];
        etfTokenCardAmount = [50, 100, 200, 500, 1000];
        governTokenCardLeft = [17, 15, 24, 5, 2, 1];
        governTokenCardAmount = [200, 500, 1000, 2000, 5000, 10000];
        tokenURIs[0] = ["QmQje33po2WU49RGUawitnKspud3VrE7HD7QV29FYsurMk", "QmR7BZBwotVcCCoeoXXCDDkRsdRSQsmGx6hUWxaXQh5sBd", "QmTcLHTucUZc4E1nQpWKptMsUkC4cP6HRnVFJXPeonJP2M", "QmZoziaXwPiX7Dwm8xTe3oRDtXXZq2c3Y2H5w5nNeD46Lq", "Qmdmu68fYuDksGmiGHBoEahA6XY9rcCM79rDLcGGhy5Pfk"];
        tokenURIs[1] = ["QmXhLtDGqjz7kzgpbNSP4KSX42X1zfcAgWDhMA9frYBQcf", "Qmbc9MF1GXZcGCodv3ZbXFcACWwmsBG3cedWxmCWbH8ys5", "QmP2ggqzQLsDA1SnkCPGwsop3L5arV6RWEbTPY5LdjfGQM", "QmSa2xfRSc7TQQ2J1MLBdfpugHGi46oDFfeA9haHtd2tNN", "QmP7HKU9f35XBRceWSAaLv8kSb6Kcc6E3s6gEwnzCeDauo"];
        tokenURIs[2] = ["QmNmSxrPbdZ9znMBuH61Baj13BtJZ65XALJncsRbGFhgse", "Qmdt51hMGD8DPbTZymS1nsZdRSP14paMfk62ok8vQuQ63J", "QmdYRtFzWFzrsu6jSPXp8BqSAfsKFgY7s3wAAGvqx1uqQs", "QmTu8ktfZm6MJrcuFXgoA8xHSzTPCt9Dj7yJBrpLDFwZLu", "QmU3jdsZofozNJ1yGhtPZBLyvYTwEcwiNzT8qmTFH4GUGL", "QmWMopbJfGTmR4eKL7DnjLwP4CP1KoTteSkheGwXMFaCfM"];
        tokenURIs[3] = ["QmW8ZgrZ2SLdeFp2RyJYzauAPiZisMoko4WgZKgNKDQpEC"];
        tokenURIs[4] = ["QmT66A8MkPRgdPZAhtzQ7o4dEYYRgKVmG64HqSWxPynq7H"];
    }
    function rand(uint256 divNum, uint256 i, uint256 j) internal view returns (uint256){
        uint256 randNum = uint256(
            keccak256(abi.encodePacked(block.number
        , msg.sender, block.timestamp, i, j))).mod(divNum);
        return randNum;
    }

    function buyNFT(uint num) external confirmSellTime {
        require(num <= 10, "buy limit");
        uint amount = num.mul(price);
        require(amount <= IERC20(mc.getMember("MDF")).allowance(msg.sender, address(this)), "not enough approve");
        require(blindBoxLeft.sub(num) >= 0, "blind box not enough");
        randNFT(num);
        IERC20(mc.getMember("MDF")).transferFrom(msg.sender, mc.getMember("BoxFee"), amount);
    }

    function randNFT(uint number) internal {
        uint nonce = 0;
        for (uint256 i = 0; i < number; i++) {
            uint256 tempBlindBoxLeft = blindBoxLeft;
            for (uint256 j = 0; j < saleNumLeft.length; j++) {
                MysteryNFT_S memory nft;
                nonce ++;
                string memory tokenURI;
                uint256 randomNum = rand(tempBlindBoxLeft, i, nonce);
                if (randomNum < saleNumLeft[j]) {
                    nft.nftType = uint32(j + 1);
                    if (j + 1 == 1) {
                        (nft.farmingAccelerateAmount, nft.farmingAcceleratePercent, tokenURI) = randAccelerateCard(saleNumLeft[j], j, nonce);
                    } else if (j + 1 == 2) {
                        (nft.etfTokenAmount, tokenURI) = randEtfTokenCard(saleNumLeft[j], j, nonce);
                    } else if (j + 1 == 3) {
                        (nft.governTokenAmount, tokenURI) = randGovernTokenCardLeft(saleNumLeft[j], j, nonce);
                    } else if (j + 1 == 4) {
                        tokenURI = tokenURIs[j][0];
                    } else if (j + 1 == 5) {
                        tokenURI = tokenURIs[j][0];
                    }
                    blindBoxLeft = blindBoxLeft.sub(1);
                    saleNumLeft[j] = saleNumLeft[j].sub(1);
                    mysteryNFT.mint(msg.sender, nft, tokenURI);
                    break;
                }
                tempBlindBoxLeft = tempBlindBoxLeft.sub(saleNumLeft[j]);
            }
        }
    }

    function randAccelerateCard(uint cardLeft, uint nftType, uint nonce) internal returns (uint32, uint32, string memory) {
        for (uint256 j = 0; j < accelerateCardLeft.length; j++) {
            uint256 randomNum = rand(cardLeft, nonce, j);
            if (randomNum < accelerateCardLeft[j]) {
                accelerateCardLeft[j] = accelerateCardLeft[j].sub(1);
                return (accelerateCardAmount[j], accelerateCardPercent[j], tokenURIs[nftType][j]);
            }
            cardLeft = cardLeft.sub(accelerateCardLeft[j]);
        }
        return (0, 0, "");
    }

    function randEtfTokenCard(uint cardLeft, uint nftType, uint nonce) internal returns (uint32, string memory) {
        for (uint256 j = 0; j < etfTokenCardLeft.length; j++) {
            uint256 randomNum = rand(cardLeft, nonce, j);
            if (randomNum < etfTokenCardLeft[j]) {
                etfTokenCardLeft[j] = etfTokenCardLeft[j].sub(1);
                return (etfTokenCardAmount[j], tokenURIs[nftType][j]);
            }
            cardLeft = cardLeft.sub(etfTokenCardLeft[j]);
        }
        return (0, "");
    }

    function randGovernTokenCardLeft(uint cardLeft, uint nftType, uint nonce) internal returns (uint32, string memory) {
        for (uint256 j = 0; j < governTokenCardLeft.length; j++) {
            uint256 randomNum = rand(cardLeft, nonce, j);
            if (randomNum < governTokenCardLeft[j]) {
                governTokenCardLeft[j] = governTokenCardLeft[j].sub(1);
                return (governTokenCardAmount[j], tokenURIs[nftType][j]);
            }
            cardLeft = cardLeft.sub(governTokenCardLeft[j]);
        }
        return (0, "");
    }
    function exchangeFundToken(uint[] memory _tokenIds, address fundAddr) external {
        address pay = mc.getMember("PAY");
        require(supportFundToken[fundAddr], "fund addr err");
        IERC20 fundToken = IERC20(fundAddr);
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(mysteryNFT.ownerOf(_tokenIds[i]) == msg.sender, "not owner");
            MysteryNFT_S memory nft = mysteryNFT.getNFTByTokenId(_tokenIds[i]);
            require(nft.nftType == 2, "nft type err");
            fundToken.transferFrom(pay, msg.sender, uint(nft.etfTokenAmount).mul(1e18));
            mysteryNFT.burn(_tokenIds[i]);
        }
    }
    function exchangeMDF(uint[] memory _tokenIds) external {
        address pay = mc.getMember("PAY");
        IERC20 mdf = IERC20(mc.getMember("MDF"));
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(mysteryNFT.ownerOf(_tokenIds[i]) == msg.sender, "not owner");
            MysteryNFT_S memory nft = mysteryNFT.getNFTByTokenId(_tokenIds[i]);
            require(nft.nftType == 3, "nft type err");
            mdf.transferFrom(pay, msg.sender, uint(nft.governTokenAmount).mul(1e18));
            mysteryNFT.burn(_tokenIds[i]);
        }
    }

    function setSupportFundToken(address fundAddr, bool b) external onlyManagers {
        supportFundToken[fundAddr] = b;
    }
    function setSellTime(uint64 _startTime, uint64 _endTime) external onlyManagers {
        sellTime.startTime = _startTime;
        sellTime.endTime = _endTime;
    }
    function setBlindBox(
        uint _blindBoxLeft,
        uint32[] memory _saleNumLeft,
        uint32[] memory _accelerateCardLeft,
        uint32[] memory _accelerateCardAmount,
        uint32[] memory _accelerateCardPercent,
        uint32[] memory _etfTokenCardLeft,
        uint32[] memory _etfTokenCardAmount,
        uint32[] memory _governTokenCardLeft,
        uint32[] memory _governTokenCardAmount) external onlyManagers {
        blindBoxLeft = _blindBoxLeft;
        saleNumLeft = _saleNumLeft;
        accelerateCardLeft = _accelerateCardLeft;
        accelerateCardAmount = _accelerateCardAmount;
        accelerateCardPercent = _accelerateCardPercent;
        etfTokenCardLeft = _etfTokenCardLeft;
        etfTokenCardAmount = _etfTokenCardAmount;
        governTokenCardLeft = _governTokenCardLeft;
        governTokenCardAmount = _governTokenCardAmount;
    }

    function updateTokenURIs(uint nftType, string[] memory URIs) external onlyManagers {
        tokenURIs[nftType] = URIs;
    }
    function aggregate() external view returns (
        uint,
        uint,
        uint32[] memory,
        uint32[] memory,
        uint32[] memory,
        uint32[] memory,
        uint32[] memory,
        uint32[] memory,
        uint32[] memory,
        uint32[] memory,
        uint32[] memory) {
        uint32[] memory st = new uint32[](2);
        st[0] = uint32(sellTime.startTime);
        st[1] = uint32(sellTime.endTime);
        return (
        price,
        blindBoxLeft,
        st,
        saleNumLeft,
        accelerateCardLeft,
        accelerateCardAmount,
        accelerateCardPercent,
        etfTokenCardLeft,
        etfTokenCardAmount,
        governTokenCardLeft,
        governTokenCardAmount);
    }
}

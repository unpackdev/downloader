//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./Data.sol";

/**
 /$$$$$$$                               /$$       /$$$$$$$            /$$          
| $$__  $$                             |__/      | $$__  $$          | $$          
| $$  \ $$ /$$$$$$  /$$$$$$$  /$$$$$$$$ /$$      | $$  \ $$ /$$$$$$$ | $$  /$$$$$$$
| $$$$$$$//$$__  $$| $$__  $$|____ /$$/| $$      | $$$$$$$/| $$__  $$| $$ /$$_____/
| $$____/| $$  \ $$| $$  \ $$   /$$$$/ | $$      | $$____/ | $$  \ $$| $$|  $$$$$$ 
| $$     | $$  | $$| $$  | $$  /$$__/  | $$      | $$      | $$  | $$| $$ \____  $$
| $$     |  $$$$$$/| $$  | $$ /$$$$$$$$| $$      | $$      | $$  | $$| $$ /$$$$$$$/
|__/      \______/ |__/  |__/|________/|__/      |__/      |__/  |__/|__/|_______/
 */

contract PonziPnls is ERC721Enumerable, Ownable {
    event PositionOpened(address trader, uint256 tokenId, uint256 hash, uint8 lottoGroup);

    uint256 public MAX_SUPPLY = 10000;
    uint256 public MINT_COST = .05 ether;
    uint256 public REFERRAL_MINT_COST = .04 ether;
    address public winnerAddress;
    uint256 public timeLastMinted;

    mapping(uint256=>uint256) public tokenHashes;
    mapping(uint8=>address[]) public lottoAddresses;
    mapping(address=>ReferralInfo) public referralTracker;

    struct ReferralInfo {
        bool started;
        uint8 remaining;
    }

    constructor(uint256 _maxSupply) ERC721("Ponzi PNLs", "PONZI") {
        MAX_SUPPLY = _maxSupply;
        timeLastMinted = block.timestamp;
    }

    function openPosition() public payable {
        uint256 tokenId = totalSupply();
        require(tokenId + 1 <= MAX_SUPPLY, 'exchange under maintenance, trading is paused lmao');
        require(msg.value >= MINT_COST, 'turns out u a larp');
        payable(owner()).transfer(msg.value / 2);
        if (referralTracker[msg.sender].started == false) {
            referralTracker[msg.sender].started = true;
            referralTracker[msg.sender].remaining = getReferralsCount(tokenId);
        }
        uint256 hash = uint256(keccak256(abi.encodePacked(tokenId, msg.sender, block.timestamp, block.difficulty)));
        tokenHashes[tokenId] = hash;
        uint8 lottoGroup = Data.getLottoGroup(hash);
        lottoAddresses[lottoGroup].push(msg.sender);
        _safeMint(msg.sender, tokenId, "");
        timeLastMinted = block.timestamp;
        emit PositionOpened(msg.sender, tokenId, hash, lottoGroup);
    }

    function getReferralsCount(uint256 _totalSupply) private pure returns (uint8 referralsCount) {
        if (_totalSupply <= 999) {
            referralsCount = 10;
        } else if (_totalSupply <=1999) {
            referralsCount = 5;
        } else if (_totalSupply <=4999) {
            referralsCount = 3;
        } else {
            referralsCount = 2;
        }
    }

    function openPositionReferral(address _referrer) public payable {
        uint256 tokenId = totalSupply();
        require(tokenId + 2 <= MAX_SUPPLY, 'exchange under maintenance, trading is paused lmao');
        require(msg.value >= REFERRAL_MINT_COST, 'turns out u a larp');
        require(msg.sender != _referrer, 'just make a new wallet kid');
        require(referralTracker[_referrer].started == true, 'referral code not found');
        require(referralTracker[_referrer].remaining >= 1, 'referral code deactivated');
        referralTracker[_referrer].remaining--;
        if (referralTracker[msg.sender].started == false) {
            referralTracker[msg.sender].started = true;
            referralTracker[msg.sender].remaining = getReferralsCount(tokenId);
        }
        payable(owner()).transfer(msg.value / 2);

        //Mint a PNL for referrer and minter
        for (uint8 i=0; i<2; i++) {
            address mintTo = (i == 0) ? msg.sender : _referrer;
            uint256 hash = uint256(keccak256(abi.encodePacked(tokenId, mintTo, block.timestamp, block.difficulty)));
            tokenHashes[tokenId+i] = hash;
            uint8 lottoGroup = Data.getLottoGroup(hash);
            lottoAddresses[lottoGroup].push(mintTo);
            _safeMint(mintTo, tokenId + i, "");
            emit PositionOpened(mintTo, tokenId, hash, lottoGroup);
        }
        timeLastMinted = block.timestamp;
    }

    function getLottoCountByGroup(uint8 _groupNum) public view returns (uint256){
        return lottoAddresses[_groupNum].length;
    }

    function chooseWinner() public {
        require(totalSupply() == MAX_SUPPLY, 'cannot draw winner yet pleb');
        require(winnerAddress == address(0), 'winner already set');
        uint256 hash = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty)));
        uint256 groupIndex = hash % 15; //returns num from 0 to 14 (total number of possible groups)
        uint256 addressesInGroup = lottoAddresses[uint8(groupIndex)].length;
        require(addressesInGroup > 0, 'no winners in this group');
        uint256 winnerIndex = hash % addressesInGroup;
        winnerAddress = lottoAddresses[uint8(groupIndex)][winnerIndex];
    }

    function endThisPonzi() public {
        require(timeLastMinted + 86400*10 < block.timestamp, 'not 10 days yet');
        MAX_SUPPLY = totalSupply();
    }

    function collectJackpot() public {
        require(msg.sender == winnerAddress, 'ye rite, u wish mate');
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(_exists(_tokenId), "cannot find ur trade order, please file a support ticket kek");
        Data.TradeInfo memory tradeInfo = Data.generateTradeInfo(tokenHashes[_tokenId]);
        string memory metadataSection1 = generateMetadataSection1(tradeInfo, _tokenId);
        string memory metadataSection2 = generateMetadataSection2(tradeInfo);
        string memory image = generateBase64Image(tradeInfo);
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            metadataSection1,
                            metadataSection2,
                            image
                        )
                    )
                )
            )
        );
    }

    function generateMetadataSection1(Data.TradeInfo memory _tradeInfo, uint256 _tokenId) private pure returns (string memory metadata) {
        return string(abi.encodePacked(
                    '{"name":"Ponzi PNL #',Data.toString(_tokenId),'", "description":"Crypto is a scam and NFTs are ponzis. If you had a chance to win a couple hundred ETH, would you take that bet or are you just a larp? ", "attributes": [{"trait_type": "Exchange", "value": "',_tradeInfo.exchange.name,'"},{"trait_type": "Side", "value": "',_tradeInfo.side,'"},{"trait_type": "Market", "value": "',_tradeInfo.market,'-USDT"},'));
    }

    function generateMetadataSection2(Data.TradeInfo memory _tradeInfo) private pure returns (string memory metadata) {
        return string(abi.encodePacked(
                    '{"trait_type": "Account Size", "value": "',_tradeInfo.accountSize,'"},{"trait_type": "Leverage", "value": "',_tradeInfo.leverage,'X','"},{"trait_type": "Lotto Entries", "value":"',_tradeInfo.lottoGroup,'"}], "image": "data:image/svg+xml;base64,'));
    }

    function generateBase64Image(Data.TradeInfo memory _tradeInfo) private pure returns (string memory image) {
        return string(abi.encodePacked(
            Base64.encode(bytes(generateImage(_tradeInfo))), '"}'
        ));
    }

    function generateImage(Data.TradeInfo memory _tradeInfo) private pure returns (string memory) {
        string memory backgroundSection = generateBgSvg(_tradeInfo);
        string memory headerSection = generateHeaderSvg(_tradeInfo);
        string memory shapesSection = generateShapesSvg(_tradeInfo);
        string memory dataSection = generateDataSvg(_tradeInfo);

        return string(
            abi.encodePacked(
                '<svg class="svgBody" width="500" height="500" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg">',
                backgroundSection,
                headerSection,
                shapesSection,
                dataSection,
                '<style>.svgBody {font-family: "Helvetica" } .tiny {font-size:10px; } .label {font-size: 12px;}.medium {font-size: 18px;}.large {font-size: 24px}.xlarge {font-size: 50px}</style>',
                '</svg>'
            )
        );
    }

    function generateBgSvg(Data.TradeInfo memory _tradeInfo) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<rect width="500" height="500" rx="20" ry="20" style="fill:rgb(33,41,53);"/><text class="label" x="350" y="35" fill="grey">Exchange</text><text class="medium" x="350" y="60" fill="',_tradeInfo.exchange.color,'">',_tradeInfo.exchange.name,'</text><line x1="0" y1="100" x2="500" y2="100" style="stroke:',_tradeInfo.exchange.color,';stroke-width:1" />'));
    }

    function generateHeaderSvg(Data.TradeInfo memory _tradeInfo) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<text class="label" x="25" y="35" fill="grey">Leverage</text><text class="medium" x="25" y="60" fill="white">',_tradeInfo.leverage,'X</text><text class="label" x="125" y="35" fill="grey">Side</text><text class="medium" x="125" y="60" fill="',keccak256(bytes(_tradeInfo.side)) == keccak256(bytes('LONG')) ? 'rgb(87,190,125)' : 'rgb(231,86,99)','">', _tradeInfo.side,'</text><text class="label" x="225" y="35" fill="grey">Market</text><text class="medium" x="225" y="60" fill="white">',_tradeInfo.market,'-USDT</text>'));
    }

    function generateShapesSvg(Data.TradeInfo memory _tradeInfo) private pure returns (string memory) {
        uint256 y1 = _tradeInfo.hash % 60;
        uint256 y2 = _tradeInfo.hash % 150;
        uint256 y3 = _tradeInfo.hash % 210;
        return string(
            abi.encodePacked(
                '<defs><radialGradient id="a" cx="396" cy="281" r="514" gradientUnits="userSpaceOnUse"><stop  offset="0" stop-color="rgb(33,41,53)"/><stop  offset="1" stop-color="rgb(33,41,53)"/></radialGradient><linearGradient id="b" gradientUnits="userSpaceOnUse" x1="400" y1="148" x2="400" y2="333"><stop offset="0"  stop-color="white" stop-opacity="0"/><stop offset="1"  stop-color="',_tradeInfo.exchange.color,'" stop-opacity="0.5"/></linearGradient></defs><g fill-opacity="0.3" y="200"><circle fill="url(#b)" cx="267.5" cy="',Data.toString(y1),'" r="300"/><circle fill="url(#b)" cx="532.5" cy="',Data.toString(y2),'" r="300"/><circle fill="url(#b)" cx="400" cy="',Data.toString(y3),'" r="300"/></g>'
            )
        );
    }

    function generateDataSvg(Data.TradeInfo memory _tradeInfo) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<text x="5%" y="40%" dominant-baseline="middle" text-anchor="left" style="fill:grey">Daily PNL</text><text class="xlarge" x="5%" y="50%" dominant-baseline="middle" text-anchor="left" style="fill:',_tradeInfo.inProfit ? 'rgb(87,190,125)' : 'rgb(231,86,99)','">',_tradeInfo.pnlText,'</text><text x="5%" y="65%" dominant-baseline="middle" text-anchor="left" style="fill:grey">Account Size</text><text class="large" x="5%" y="70%" dominant-baseline="middle" text-anchor="left" style="fill:#FAF9F6">',_tradeInfo.accountSize,'</text><text x="50%" y="65%" dominant-baseline="middle" text-anchor="left" style="fill:grey">Lotto Entries</text><text class="large" x="50%" y="70%" dominant-baseline="middle" text-anchor="left" style="fill:#FAF9F6">',_tradeInfo.lottoGroup,'</text>'
            )
        );
    }
}

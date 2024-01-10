// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//         d8888 888                           d8b 888    888
//        d88888 888                           Y8P 888    888
//       d88P888 888                               888    888
//      d88P 888 888  .d88b.   .d88b.  888d888 888 888888 88888b.  88888b.d88b.  .d8888b
//     d88P  888 888 d88P"88b d88""88b 888P"   888 888    888 "88b 888 "888 "88b 88K
//    d88P   888 888 888  888 888  888 888     888 888    888  888 888  888  888 "Y8888b.
//   d8888888888 888 Y88b 888 Y88..88P 888     888 Y88b.  888  888 888  888  888      X88 d8b
//  d88P     888 888  "Y88888  "Y88P"  888     888  "Y888 888  888 888  888  888  88888P' Y8P
//                        888
//                   Y8b d88P
//                    "Y88P"
//  8888888b.                         888                             888       888          888 888
//  888   Y88b                        888                             888   o   888          888 888
//  888    888                        888                             888  d8b  888          888 888
//  888   d88P  8888b.  88888b.   .d88888  .d88b.  88888b.d88b.       888 d888b 888  8888b.  888 888  888
//  8888888P"      "88b 888 "88b d88" 888 d88""88b 888 "888 "88b      888d88888b888     "88b 888 888 .88P
//  888 T88b   .d888888 888  888 888  888 888  888 888  888  888      88888P Y88888 .d888888 888 888888K
//  888  T88b  888  888 888  888 Y88b 888 Y88..88P 888  888  888      8888P   Y8888 888  888 888 888 "88b
//  888   T88b "Y888888 888  888  "Y88888  "Y88P"  888  888  888      888P     Y888 "Y888888 888 888  888
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract TheRandomWalk is ERC721, Ownable {
    using Strings for uint256;

    // Token counter
    uint public lastTokenId;
    // Starting supply
    uint256 public totalSupply = 1024;
    // Starting price
    uint256 public currentPrice;
    // Base URI for metadata
    string private metadataBaseURI;
    // Public sale status
    bool public onSale = false;

    // Referral program
    address public defaultReferrer;
    uint8 public rewardsPct = 20;
    mapping(address => uint) public referralCount;
    mapping(address => uint) public rewardsPaid;
    address[] private _referrers;
    uint public totalReferralCount;
    uint private _totalRoyaltiesReceived;
    uint private _totalRewardsPaid;
    event RewardPaid(address referrer, uint amount);
    event RewardPaymentFailed(address referrer, uint amount);

    constructor(uint _price) ERC721("Algorithms. Random Walk", "ALGRW") {
        currentPrice = _price;
    }

    function mint(uint qty, address referrer) external payable {
        require(onSale, "Not on sale");
        require(lastTokenId + qty <= totalSupply, "Not enough supply");
        require(msg.value >= qty * currentPrice, "Insufficient funds");

        // Set referrer, if any
        // Use defaultReferrer if specified
        if (referrer == address(0) && defaultReferrer != address(0))
            referrer = defaultReferrer;
        if (referrer != address(0) && referrer != msg.sender) {
            if (referralCount[referrer] == 0)
                _referrers.push(referrer);
            referralCount[referrer] += qty;
            totalReferralCount += qty;
        }

        for (uint i = 0; i < qty; i++) {
            lastTokenId++;
            _safeMint(msg.sender, lastTokenId);
        }
    }

    // Frontend-only call
    function listTokens(address _addr) external view returns (uint[] memory) {
        uint cnt = balanceOf(_addr);
        if (cnt == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](cnt);
            uint resIdx = 0;
            for (uint i = 1; i <= lastTokenId; i++) {
                if (ownerOf(i) == _addr) {
                    result[resIdx] = i;
                    cnt--;
                    if (cnt == 0)
                        return result;
                    else
                        resIdx++;
                }
            }
            return result;
        }
    }

    // While minting, we'll have the metadata load from our website.
    // Once all is minted, we will upload all metadata to IPFS and set base URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (bytes(metadataBaseURI).length == 0)
            return string(abi.encodePacked("https://generart.io/collections/trw/", tokenId.toString(), ".json"));
        else
            return string(abi.encodePacked(metadataBaseURI, tokenId.toString()));
    }

    // Rewards payable to caller.
    // Includes mint rewards and royalties, less already paid rewards
    function payableRewards() public view returns (uint) {
        return referralCount[msg.sender] * (currentPrice + _totalRoyaltiesReceived / lastTokenId) * rewardsPct / 100 - rewardsPaid[msg.sender];
    }

    // Anyone can claim their reward.
    // Reentrancy-protected
    function claimRewards() external {
        uint toPay = payableRewards();
        require(toPay > 0, "Insufficient funds");
        rewardsPaid[msg.sender] += toPay;
        _totalRewardsPaid += toPay;

        (bool sent,) = msg.sender.call{value : toPay}("");
        if (sent)
            emit RewardPaid(msg.sender, toPay);
        else
            emit RewardPaymentFailed(msg.sender, toPay);
        require(sent);
    }

    // Every unidentified deposit to the contract
    // will be considered as royalty
    receive() external payable {
        _totalRoyaltiesReceived += msg.value;
    }

    //
    // Owner(s) functions
    //

    function updatePricing(uint256 _price) external onlyOwner {
        require(_price > 0, "Invalid price");
        currentPrice = _price;
    }

    function lockedRewardsAmount() public view onlyOwner returns (uint) {
        return totalReferralCount * (currentPrice + _totalRoyaltiesReceived / lastTokenId) * rewardsPct / 100 - _totalRewardsPaid;
    }

    function availableToWithdraw() public view onlyOwner returns (uint) {
        if (address(this).balance > lockedRewardsAmount())
            return address(this).balance - lockedRewardsAmount();
        else
            return 0;
    }

    // This function locks unpaid referral rewards (as defined in availableToWithdraw)
    // and ensures funds always remain available in the contract and claimable.
    // It then withdraws the specified amount to specified payee
    function withdraw(address payee, uint amount) external onlyOwner {
        if (amount == 0)
            amount = availableToWithdraw();
        else
            require(amount <= availableToWithdraw(), "Insufficient funds");
        require(amount > 0, "Insufficient funds");
        (bool sent,) = payee.call{value : amount}("");
        require(sent);
    }

    function mintFor(address[] memory to, uint[] memory qty) external onlyOwner {
        require(to.length == qty.length);

        for (uint16 i = 0; i < to.length; i++)
            for (uint16 j = 0; j < qty[i]; j++) {
                require(lastTokenId < totalSupply, "Not enough supply");
                lastTokenId++;
                _safeMint(to[i], lastTokenId);
            }
    }

    function setMetadataBaseUri(string memory uri) external onlyOwner {
        metadataBaseURI = uri;
    }

    function getReferrers() external view onlyOwner returns (address[] memory) {
        return _referrers;
    }

    function setDefaultReferrer(address _ref) external onlyOwner {
        defaultReferrer = _ref;
    }

    function setRewardPct(uint8 pct) external onlyOwner {
        rewardsPct = pct;
    }

    function setOnSale(bool _onSale) external onlyOwner {
        onSale = _onSale;
    }
}
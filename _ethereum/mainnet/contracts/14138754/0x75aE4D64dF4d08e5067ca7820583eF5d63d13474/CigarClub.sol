// SPDX-License-Identifier: MIT

/*
                                          «∩ⁿ─╖
                                       ⌐  ╦╠Σ▌╓┴                        .⌐─≈-,
                                ≤╠╠╠╫╕╬╦╜              ┌"░░░░░░░░░░≈╖φ░╔╦╬░░Σ╜^
                               ¼,╠.:╬╬╦╖╔≡p               "╙φ░ ╠╩╚`  ░╩░╟╓╜
                                   Γ╠▀╬═┘`                         Θ Å░▄
                      ,,,,,        ┌#                             ]  ▌░░╕
             ,-─S╜" ,⌐"",`░░φ░░░░S>╫▐                             ╩  ░░░░¼
            ╙ⁿ═s, <░φ╬░░φù ░░░░░░░░╬╠░░"Zw,                    ,─╓φ░Å░░╩╧w¼
            ∩²≥┴╝δ»╬░╝░░╩░╓║╙░░░░░░Åφ▄φ░░╦≥░⌠░≥╖,          ,≈"╓φ░░░╬╬░░╕ {⌐\
            } ▐      ½,#░░░░░╦╚░░╬╜Σ░p╠░░╬╘░░░░╩  ^"¥7"""░"¬╖╠░░░#▒░░░╩ φ╩ ∩
              Γ      ╬░⌐"╢╙φ░░▒╬╓╓░░░░▄▄╬▄░╬░░Å░░░░╠░╦,φ╠░░░░░░-"╠░╩╩  ê░Γ╠
             ╘░,,   ╠╬     '░╗Σ╢░░░░░░▀╢▓▒▒╬╬░╦#####≥╨░░░╝╜╙` ,φ╬░░░. é░░╔⌐
              ▐░ `^Σ░▒╗,   ▐░░░░░ ▒░"╙Σ░╨▀╜╬░▓▓▓▓▓▓▀▀░»φ░N  ╔╬▒░░░"`,╬≥░░╢
               \  ╠░░░░░░╬#╩╣▄░Γ, ▐░,φ╬▄Å` ░ ```"╚░░░░,╓▄▄▄╬▀▀░╠╙░╔╬░░░ ½"
                └ '░░░░░░╦╠ ╟▒M╗▄▄,▄▄▄╗#▒╬▒╠"╙╙╙╙╙╙╢▒▒▓▀▀░░░░░╠╦#░░░░╚,╩
                  ¼░░░░░░░⌂╦ ▀░░░╚╙░╚▓▒▀░░░½░░╠╜   ╘▀░░░╩╩╩,▄╣╬░░░░░╙╔╩
                    ╢^╙╨╠░░▄æ,Σ ",╓╥m╬░░░░░░░Θ░φ░φ▄ ╬╬░,▄#▒▀░░░░░≥░░#`
                      *╓,╙φ░░░░░#░░░░░░░#╬╠╩ ╠╩╚╠╟▓▄╣▒▓╬▓▀░░░░░╩░╓═^
                          `"╜╧Σ░░░Σ░░░░░░╬▓µ ─"░░░░░░░░░░╜░╬▄≈"
                                    `"╙╜╜╜╝╩ÅΣM≡,`╙╚░╙╙░╜|  ╙╙╙┴7≥╗
                                                   `"┴╙¬¬¬┴┴╙╙╙╙""
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./CIGAR.sol";
import "./TreasureChest.sol";
import "./Whales.sol";
import "./SecurityOrcas.sol";
import "./WealthyWhales.sol";

contract CigarClub is Ownable, IERC721Receiver {

    struct WhaleOrcaStakeInfo {
        uint16 orcaTokenId;
        address owner;
        uint256 stakeTimestamp;
    }

    struct WhaleWhaleStakeInfo {
        uint16 whaleToken2Id;
        address owner;
        uint256 stakeTimestamp;
    }

    struct WealthyWhaleStakeInfo {
        uint256 previousCigarVaultAmount;
        uint256 stakeTimestamp;
        address owner;
    }

    // base rate
    uint256 public constant DAILY_WHALE_RATE = 10000 ether;
    // 1.25 rate
    uint256 public constant DAILY_WHALE_ORCA_RATE = DAILY_WHALE_RATE + (DAILY_WHALE_RATE / 4);
    // 2.5 rate
    uint256 public constant DAILY_GOLD_WHALE_RATE = (2 * DAILY_WHALE_RATE) + (DAILY_WHALE_RATE / 2);
    // 3 rate
    uint256 public constant DAILY_WHALE_YACHT_RATE = (3 * DAILY_WHALE_RATE);
    // 3.125 rate
    uint256 public constant DAILY_GOLD_WHALE_ORCA_RATE = (3 * DAILY_WHALE_RATE) + (DAILY_WHALE_RATE / 8);
    // 5x rate
    uint256 public constant DAILY_DOUBLE_GOLD_WHALE_RATE = 5 * DAILY_WHALE_RATE;
    // 7.5 rate
    uint256 public constant DAILY_GOLD_WHALE_YACHT_RATE = (7 * DAILY_WHALE_RATE) + (DAILY_WHALE_RATE / 2);

    uint256 public constant MIN_STAKING_TIME_WHALES = 2 days;
    uint256 public constant MIN_STAKING_TIME_WEALTHY_WHALES = 6 days;
    uint256 public constant WEALTHY_WHALE_TAX = 20;
    uint256 public constant ZERO_WHALE = 10000;

    CIGAR public cigar;
    Whales public immutable whales;
    SecurityOrcas public immutable securityOrcas;
    WealthyWhales public immutable wealthyWhales;

    // Whale Orca pairing info
    mapping(uint256 => WhaleOrcaStakeInfo) public whaleOrcaClub;

    // Whale whale pairing info
    mapping(uint256 => WhaleWhaleStakeInfo) public whaleWhaleClub;

    // Wealthy whale info
    mapping(uint256 => WealthyWhaleStakeInfo) public wealthyWhaleClub;

    // staking info for nfts sent using safeTransferFrom
    // map from user address to whale id sent
    mapping(address => uint256) public whaleStaked;

    // Total tokens staked
    uint256 public totalWhaleOrcasStaked;
    uint256 public totalWhaleWhalesStaked;
    uint256 public totalWealthyWhalesStaked;

    // Wealthy whale vault
    uint256 public unclaimedWealthyWhaleVault;
    uint256 public wealthyWhaleVault;

    // Cigar limits
    uint256 public immutable cigarStakingCap;
    uint256 public cigarAwarded;

    // gold whales and yachts
    mapping(uint256 => bool) public isGoldWhale;
    mapping(uint256 => bool) public isYacht;

    mapping(uint256 => uint256) public whaleIdToRate;
    mapping(uint256 => uint256) public orcaIdToRate;

    event WhaleOrcaStaked(address owner, uint256 whaleId, uint256 orcaId, uint256 timestamp);
    event WhaleWhaleStaked(address owner, uint256 whaleId, uint256 whale2Id, uint256 timestamp);
    event WealthyWhaleStaked(address owner, uint256 tokenId, uint256 wealthyWhaleVault, uint256 timestamp);

    event RewardsClaimedWhaleOrca(address owner, uint256 whaleId, uint256 orcaId, uint256 timestamp);
    event RewardsClaimedWhaleWhale(address owner, uint256 whaleId, uint256 whale2Id, uint256 timestamp);
    event RewardsClaimedWealthyWhale(address owner, uint256 tokenId, uint256 wealthyWhaleVault, uint256 timestamp);

    event WhaleOrcaUnstaked(address owner, uint256 whaleId, uint256 orcaId, uint256 timestamp);
    event WhaleWhaleUnstaked(address owner, uint256 whaleId, uint256 whale2Id, uint256 timestamp);
    event WealthyWhaleUnstaked(address owner, uint256 tokenId, uint256 wealthyWhaleVault, uint256 timestamp);

    constructor(address _whales, address _securityOrcas, address _cigar, address _wealthyWhales) {
        whales = Whales(_whales);
        securityOrcas = SecurityOrcas(_securityOrcas);
        cigar = CIGAR(_cigar);
        wealthyWhales = WealthyWhales(_wealthyWhales);

        cigarStakingCap = cigar.STAKING_AMOUNT();
    }

    function stakeWhalesAndOrcasInCigarClub(uint256[] calldata whaleIds, uint256[] calldata orcaIds) external {
        require(whaleIds.length == orcaIds.length, "Must stake an equal number of whales and orcas!");
        for (uint i = 0; i < whaleIds.length; i++) {
            require(whales.ownerOf(whaleIds[i]) == _msgSender(), "This is not your whale!");
            require(securityOrcas.ownerOf(orcaIds[i]) == _msgSender(), "This is not your orca!");

            whales.transferFrom(_msgSender(), address(this), whaleIds[i]);
            securityOrcas.transferFrom(_msgSender(), address(this), orcaIds[i]);
            _addWhaleAndOrcaToCigarClub(_msgSender(), whaleIds[i], orcaIds[i]);
        }
        totalWhaleOrcasStaked += whaleIds.length;
    }

    function stakeWhalesInCigarClub(uint256[] calldata whaleIds) external {
        require(whaleIds.length > 1, "Must provide at least 2 whaleIds");
        require(whaleIds.length % 2 == 0, "Must be even number of whales");
        for (uint i = 0; i < whaleIds.length; i += 2) {
            require(whales.ownerOf(whaleIds[i]) == _msgSender(), "This is not your whale!");
            require(whales.ownerOf(whaleIds[i + 1]) == _msgSender(), "This is not your whale!");

            whales.transferFrom(_msgSender(), address(this), whaleIds[i]);
            whales.transferFrom(_msgSender(), address(this), whaleIds[i + 1]);
            _addWhalesToCigarClub(_msgSender(), whaleIds[i], whaleIds[i + 1]);
        }

        totalWhaleWhalesStaked += whaleIds.length / 2;
    }

    function stakeWealthyWhalesInCigarClub(uint256[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(wealthyWhales.ownerOf(tokenIds[i]) == _msgSender(), "This is not your token!");
            wealthyWhales.transferFrom(_msgSender(), address(this), tokenIds[i]);
            _addWealthyWhaleToCigarClub(_msgSender(), tokenIds[i]);
        }
    }

    function claimWhalesAndOrcas(uint256[] calldata whaleIds, bool unstake) external {
        uint256 reward;
        for (uint i = 0; i < whaleIds.length; i++) {
            reward += _claimWhaleOrcaAndGetReward(whaleIds[i], unstake);
        }

        if (reward == 0) return;
        cigar.mint(_msgSender(), reward);
    }

    // must only use the primary whale ids being staked
    function claimWhales(uint256[] calldata whaleIds, bool unstake) external {
        require(whaleIds.length > 0, "Must claim at least 1 whale");
        uint256 reward;
        for (uint i = 0; i < whaleIds.length; i++) {
            reward += _claimWhalesAndGetReward(whaleIds[i], unstake);
        }

        if (reward == 0) return;
        cigar.mint(_msgSender(), reward);
    }

    function claimWealthyWhales(uint256[] calldata tokenIds, bool unstake) external {
        uint256 reward;
        for (uint i = 0; i < tokenIds.length; i++) {
            reward += _claimWealthyWhaleAndGetReward(tokenIds[i], unstake);
        }

        if (reward == 0) return;
        cigar.mint(_msgSender(), reward);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        external override returns (bytes4) {

        require(msg.sender == address(securityOrcas) || msg.sender == address(whales),
            "Only accepts whale and security orca tokens");
        uint256 currentWhale = whaleStaked[from];

        if (msg.sender == address(whales)) {
            require(currentWhale == 0, "Must not have sent other unstaked whales");
            if (tokenId == 0) {
                whaleStaked[from] = ZERO_WHALE;
            } else {
                whaleStaked[from] = tokenId;
            }
        } else if (msg.sender == address(securityOrcas)) {
            require(currentWhale != 0, "This address must have deposited a whale first!");
            if (currentWhale == ZERO_WHALE) {
                currentWhale = 0;
            }

            _addWhaleAndOrcaToCigarClub(from, currentWhale, tokenId);
            whaleStaked[from] = 0;
            totalWhaleOrcasStaked++;
        }

        return IERC721Receiver.onERC721Received.selector;
    }

    function retrieveLoneWhale() external {
        uint256 whaleId = whaleStaked[_msgSender()];
        require(whaleId != 0, "User must have sent an unstaked whale");

        whaleStaked[_msgSender()] = 0;
        whales.safeTransferFrom(address(this), _msgSender(), whaleId, "");
    }

    function setGoldWhales(uint256[] calldata goldWhaleIds) external onlyOwner {
        for(uint256 i = 0; i < goldWhaleIds.length; i++) {
            isGoldWhale[goldWhaleIds[i]] = true;
        }
    }

    function setYachts(uint256[] calldata yachtIds) external onlyOwner {
        for(uint256 i = 0; i < yachtIds.length; i++) {
            isYacht[yachtIds[i]] = true;
        }
    }

    function setWhaleRates(uint256[] calldata whaleIds, uint256 rate) external onlyOwner {
        for (uint i = 0; i < whaleIds.length; i++) {
            whaleIdToRate[whaleIds[i]] = rate;
        }
    }

    function setOrcaRates(uint256[] calldata orcaIds, uint256 rate) external onlyOwner {
        for (uint i = 0; i < orcaIds.length; i++) {
            orcaIdToRate[orcaIds[i]] = rate;
        }
    }

    function getDailyRateWhaleOrca(uint256 whaleId, uint256 orcaId) public view returns (uint256) {
        uint256 bonusWhaleRate = whaleIdToRate[whaleId];
        uint256 bonusOrcaRate = orcaIdToRate[orcaId];
        if (bonusWhaleRate == 0) {
            bonusWhaleRate = 1;
        }

        if (bonusOrcaRate == 0) {
            bonusOrcaRate = 1;
        }

        if (bonusWhaleRate != 1 || bonusOrcaRate != 1) {
            return DAILY_WHALE_ORCA_RATE * bonusWhaleRate * bonusOrcaRate;
        }

        bool goldWhale = isGoldWhale[whaleId];
        bool yacht = isYacht[orcaId];

        if (goldWhale && yacht) {
            return DAILY_GOLD_WHALE_YACHT_RATE;
        } else if (goldWhale) {
            return DAILY_GOLD_WHALE_ORCA_RATE;
        } else if (yacht) {
            return DAILY_WHALE_YACHT_RATE;
        } else {
            return DAILY_WHALE_ORCA_RATE;
        }
    }

    function getDailyRateWhaleWhale(uint256 whaleId, uint256 whale2Id) public view returns (uint256) {
        uint256 bonusWhaleRate1 = whaleIdToRate[whaleId];
        uint256 bonusWhaleRate2 = whaleIdToRate[whale2Id];

        if (bonusWhaleRate1 == 0) {
            bonusWhaleRate1 = 1;
        }

        if (bonusWhaleRate2 == 0) {
            bonusWhaleRate2 = 1;
        }

        if (bonusWhaleRate1 != 1 || bonusWhaleRate2 != 1) {
            return DAILY_WHALE_RATE * bonusWhaleRate1 * bonusWhaleRate2;
        }

        bool isWhale1Gold = isGoldWhale[whaleId];
        bool isWhale2Gold = isGoldWhale[whale2Id];

        if (isWhale1Gold && isWhale2Gold) {
            return DAILY_DOUBLE_GOLD_WHALE_RATE;
        } else if (isWhale1Gold || isWhale2Gold) {
            return DAILY_GOLD_WHALE_RATE;
        } else {
            return DAILY_WHALE_RATE;
        }
    }

    // INTERNAL FUNCTIONS

    function _addWhaleAndOrcaToCigarClub(address account, uint256 whaleId, uint256 orcaId) internal {
        whaleOrcaClub[whaleId] = WhaleOrcaStakeInfo({
            owner: account,
            orcaTokenId: uint16(orcaId),
            stakeTimestamp: block.timestamp
        });

        emit WhaleOrcaStaked(account, whaleId, orcaId, block.timestamp);
    }

    function _addWhalesToCigarClub(address account, uint256 whaleId, uint256 whale2Id) internal {
        whaleWhaleClub[whaleId] = WhaleWhaleStakeInfo({
            owner: account,
            whaleToken2Id: uint16(whale2Id),
            stakeTimestamp: block.timestamp
        });

        emit WhaleWhaleStaked(account, whaleId, whale2Id, block.timestamp);
    }

    function _addWealthyWhaleToCigarClub(address account, uint256 tokenId) internal {
        wealthyWhaleClub[tokenId] = WealthyWhaleStakeInfo({
            owner: account,
            stakeTimestamp: block.timestamp,
            previousCigarVaultAmount: wealthyWhaleVault
        });

        totalWealthyWhalesStaked += 1;
        emit WealthyWhaleStaked(account, tokenId, wealthyWhaleVault, block.timestamp);
    }

    function _claimWhaleOrcaAndGetReward(uint256 whaleId, bool unstake) internal returns (uint256) {
        WhaleOrcaStakeInfo memory stakeInfo = whaleOrcaClub[whaleId];
        require(stakeInfo.owner == _msgSender(), "This whale is owned by someone else.");
        uint256 timeStaked = block.timestamp - stakeInfo.stakeTimestamp;

        require(timeStaked > MIN_STAKING_TIME_WHALES, "Must have staked for at least 2 days!");
        uint256 rewardRate = getDailyRateWhaleOrca(whaleId, stakeInfo.orcaTokenId);
        uint256 reward = timeStaked * rewardRate / 1 days;
        reward = _loadWealthyWhaleVault(reward);
        if (cigarAwarded + reward > cigarStakingCap) {
            reward = cigarStakingCap - cigarAwarded;
        }

        if (unstake) {
            uint256 securityOrcaId = stakeInfo.orcaTokenId;
            whales.safeTransferFrom(address(this), _msgSender(), whaleId, "");
            securityOrcas.safeTransferFrom(address(this), _msgSender(), securityOrcaId, "");

            delete whaleOrcaClub[whaleId];
            totalWhaleOrcasStaked -= 1;
            emit WhaleOrcaUnstaked(_msgSender(), whaleId, securityOrcaId, block.timestamp);
        } else {
            whaleOrcaClub[whaleId].stakeTimestamp = block.timestamp;
            emit RewardsClaimedWhaleOrca(_msgSender(), whaleId, stakeInfo.orcaTokenId, block.timestamp);
        }

        cigarAwarded += reward;
        return reward;
    }

    function _claimWhalesAndGetReward(uint256 whaleId, bool unstake) internal returns (uint256) {
        WhaleWhaleStakeInfo memory stakeInfo = whaleWhaleClub[whaleId];
        require(stakeInfo.owner == _msgSender(), "This whale is owned by someone else.");
        uint256 timeStaked = block.timestamp - stakeInfo.stakeTimestamp;

        require(timeStaked > MIN_STAKING_TIME_WHALES, "Must have staked for at least 2 days!");
        uint256 rewardRate = getDailyRateWhaleWhale(whaleId, stakeInfo.whaleToken2Id);
        uint256 reward = timeStaked * rewardRate / 1 days;
        reward = _loadWealthyWhaleVault(reward);
        if (cigarAwarded + reward > cigarStakingCap) {
            reward = cigarStakingCap - cigarAwarded;
        }

        if (unstake) {
            whales.safeTransferFrom(address(this), _msgSender(), whaleId, "");
            whales.safeTransferFrom(address(this), _msgSender(), stakeInfo.whaleToken2Id, "");

            delete whaleWhaleClub[whaleId];

            totalWhaleWhalesStaked -= 1;
            emit WhaleWhaleUnstaked(_msgSender(), whaleId, stakeInfo.whaleToken2Id, block.timestamp);
        } else {
            whaleWhaleClub[whaleId].stakeTimestamp = block.timestamp;
            emit RewardsClaimedWhaleWhale(_msgSender(), whaleId, stakeInfo.whaleToken2Id, block.timestamp);
        }

        cigarAwarded += reward;
        return reward;
    }


    function _claimWealthyWhaleAndGetReward(uint256 tokenId, bool unstake) internal returns (uint256) {
        WealthyWhaleStakeInfo memory stakeInfo = wealthyWhaleClub[tokenId];
        require(stakeInfo.owner == _msgSender(), "This wealthy whale is owned by someone else");
        uint256 timeStaked = block.timestamp - stakeInfo.stakeTimestamp;
        require(timeStaked > MIN_STAKING_TIME_WEALTHY_WHALES, "Must have staked for at least 6 days!");

        uint256 reward = wealthyWhaleVault - stakeInfo.previousCigarVaultAmount;
        if (cigarAwarded + reward > cigarStakingCap) {
            reward = cigarStakingCap - cigarAwarded;
        }

        if (unstake) {
            wealthyWhales.safeTransferFrom(address(this), _msgSender(), tokenId, "");

            delete wealthyWhaleClub[tokenId];
            totalWealthyWhalesStaked -= 1;
            emit WealthyWhaleUnstaked(_msgSender(), tokenId, wealthyWhaleVault, block.timestamp);
        } else {
            wealthyWhaleClub[tokenId].previousCigarVaultAmount = wealthyWhaleVault;
            emit RewardsClaimedWealthyWhale(_msgSender(), tokenId, wealthyWhaleVault, block.timestamp);
        }

        cigarAwarded += reward;
        return reward;
    }

    function _loadWealthyWhaleVault(uint256 whaleReward) internal returns (uint256) {
        uint256 wealthyWhaleTribute = whaleReward * WEALTHY_WHALE_TAX / 100;
        if (totalWealthyWhalesStaked == 0) {
            unclaimedWealthyWhaleVault += wealthyWhaleTribute;
        } else {
            wealthyWhaleVault += (wealthyWhaleTribute + unclaimedWealthyWhaleVault)
                / totalWealthyWhalesStaked;
            unclaimedWealthyWhaleVault = 0;
        }

        return whaleReward - wealthyWhaleTribute;
    }
}
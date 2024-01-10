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
import "./CigarClub.sol";
import "./WealthyWhales.sol";
import "./WealthyWhales2.sol";

contract CigarClub2 is Ownable {

    struct WealthyWhaleStakeInfo {
        uint256 previousCigarVaultAmount;
        uint256 stakeTimestamp;
        address owner;
    }

    uint256 public constant WEALTHY_WHALE_TAX = 20;
    uint256 public constant MIN_STAKING_TIME_WEALTHY_WHALES = 6 days;

    CIGAR public cigar;
    CigarClub public cigarClub;
    WealthyWhales2 public immutable wealthyWhales2;

    // Wealthy whale info
    mapping(uint256 => WealthyWhaleStakeInfo) public wealthyWhaleClub;

    uint256 public totalWealthyWhalesStaked;

    uint256 public wealthyWhaleVault;

    // Cigar limits
    uint256 constant CAP = 750000000000 ether;
    uint256 public cigarAwarded;

    event WealthyWhaleStaked(address owner, uint256 tokenId, uint256 wealthyWhaleVault, uint256 timestamp);
    event RewardsClaimedWealthyWhale(address owner, uint256 tokenId, uint256 wealthyWhaleVault, uint256 timestamp);
    event WealthyWhaleUnstaked(address owner, uint256 tokenId, uint256 wealthyWhaleVault, uint256 timestamp);

    constructor(address _cigar, address _wealthyWhales2) {
        cigar = CIGAR(_cigar);
        wealthyWhales2 = WealthyWhales2(_wealthyWhales2);
    }

    function stakeWealthyWhalesInCigarClub(uint256[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(wealthyWhales2.ownerOf(tokenIds[i]) == _msgSender(), "This is not your token!");
            wealthyWhales2.transferFrom(_msgSender(), address(this), tokenIds[i]);
            _addWealthyWhaleToCigarClub(_msgSender(), tokenIds[i]);
        }
    }

    function claimWealthyWhales(uint256[] calldata tokenIds, bool unstake) external {
        uint256 reward;
        for (uint i = 0; i < tokenIds.length; i++) {
            reward += _claimWealthyWhaleAndGetReward(tokenIds[i], unstake);
        }

        if (reward == 0) return;
        cigar.mint(_msgSender(), reward);
    }

    function setCigarClub(address _cigarClub) external onlyOwner {
        cigarClub = CigarClub(_cigarClub);
    }

    // INTERNAL FUNCTIONS

    function _addWealthyWhaleToCigarClub(address account, uint256 tokenId) internal {
        wealthyWhaleVault = cigarClub.wealthyWhaleVault();
        wealthyWhaleClub[tokenId] = WealthyWhaleStakeInfo({
        owner: account,
        stakeTimestamp: block.timestamp,
        previousCigarVaultAmount: wealthyWhaleVault
        });

        totalWealthyWhalesStaked += 1;
        emit WealthyWhaleStaked(account, tokenId, wealthyWhaleVault, block.timestamp);
    }

    function _claimWealthyWhaleAndGetReward(uint256 tokenId, bool unstake) internal returns (uint256) {
        WealthyWhaleStakeInfo memory stakeInfo = wealthyWhaleClub[tokenId];
        require(stakeInfo.owner == _msgSender(), "This wealthy whale is owned by someone else");
        uint256 timeStaked = block.timestamp - stakeInfo.stakeTimestamp;
        require(timeStaked > MIN_STAKING_TIME_WEALTHY_WHALES, "Must have staked for at least 6 days!");

        wealthyWhaleVault = cigarClub.wealthyWhaleVault();

        uint256 reward = wealthyWhaleVault - stakeInfo.previousCigarVaultAmount;
        if (cigarAwarded + reward > CAP) {
            reward = CAP - cigarAwarded;
        }

        if (unstake) {
            wealthyWhales2.safeTransferFrom(address(this), _msgSender(), tokenId, "");

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
}
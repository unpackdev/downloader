// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";
import "./XENCrypto.sol";
import "./IBurnableToken.sol";
import "./IBurnRedeemable.sol";
import "./XENFT.sol";
import "./XENStake.sol";
import "./VMPX.sol";

import "./MintInfo_.sol";
import "./StakeInfo_.sol";

contract XONE is
    Ownable,
    IBurnableToken,
    ERC20("XONE", "XONE"),
    ERC20Capped(1_000_000_000 ether)
{

    using MintInfo_ for uint256;
    using StakeInfo_ for uint256;

    uint256 public constant BATCH_FLOOR = 1_000 ether;
    uint256 public constant BATCH_XEN = 10_000 ether;
    uint256 public constant BATCH_XEN_STAKE = 10_000 ether;
    uint256 public constant BATCH_STAKE_XENFT = 10_000 ether;
    uint256 public constant BATCH_VMPX = 10_000 ether;
    uint256 public constant BATCH_XEN_BURN = 12_000 ether;
    uint256 public constant BATCH_COLLECTOR_XENFT = 12_000 ether;
    uint256 public constant BATCH_LIMITED_XENFT = 15_000 ether;
    uint256 public constant BATCH_APEX_RARE_XENFT = 20_000 ether;
    uint256 public constant BATCH_APEX_EPIC_XENFT = 30_000 ether;
    uint256 public constant BATCH_APEX_LEGENDARY_XENFT = 50_000 ether;
    uint256 public constant BATCH_APEX_EXOTIC_XENFT = 100_000 ether;
    uint256 public constant BATCH_APEX_XUNICORN_XENFT = 1_000_000 ether;

    uint256 public constant START_TRANSFER_MARGIN = 100_000 ether;

    uint256 public constant XEN_THRESHOLD = 1_000_000 ether - 1 ether;
    uint256 public constant VMPX_THRESHOLD = 10 ether - 1 ether;

    uint256 public constant XONE_MIN_BURN = 0;

    string public constant AUTHORS = "@MrJackLevin @ackebom @lbelyaev faircrypto.org";

    XENCrypto public immutable xenCrypto;
    XENTorrent public immutable xenTorrent;
    XENStake public immutable xenStake;
    VMPX public immutable vmpx;
    uint256 public immutable startBlockNumber;

    bool public mintingFinished;
    // user address => XONE mint amount
    mapping(address => uint256) public userMints;
    // tokenId => user address
    mapping(uint256 => address) public torrentTokensUsed;
    // tokenId => user address
    mapping(uint256 => address) public stakeTokensUsed;
    // user address => XEN burn amount
    mapping(address => uint256) public userBurns;

    constructor(
        address xenCryptoAddress,
        address xenTorrentAddress,
        address xenStakeAddress,
        address vmpxAddress,
        uint256 startBlockNumber_
    ) {
        xenCrypto = XENCrypto(xenCryptoAddress);
        xenTorrent = XENTorrent(xenTorrentAddress);
        xenStake = XENStake(xenStakeAddress);
        vmpx = VMPX(vmpxAddress);
        startBlockNumber = startBlockNumber_;
        _mint(owner(), cap() / 2);
    }

    modifier notBeforeStart() {
        require(block.number > startBlockNumber, "XONE: Not active yet");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(mintingFinished || from == address(0), "XONE: minting not finished");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (from == address(0) && !mintingFinished && cap() - totalSupply() < START_TRANSFER_MARGIN) {
           mintingFinished = true;
        }
    }

    function _hasXEN() internal view returns (bool) {
        return ERC20(address(xenCrypto)).balanceOf(_msgSender()) > XEN_THRESHOLD;
    }

    function _hasXENStake() internal view returns (bool) {
        (, , uint256 amount, ) =  xenCrypto.userStakes(_msgSender());
        return amount > XEN_THRESHOLD;
    }

    function _hasXENBurns() internal view returns (bool) {
        return xenCrypto.userBurns(_msgSender()) > XEN_THRESHOLD;
    }

    function _hasVMPX() internal view returns (bool) {
        return ERC20(address(vmpx)).balanceOf(_msgSender()) > VMPX_THRESHOLD;
    }

    function _hasXeNFT() internal view returns (bool) {
        return ERC721(address(xenTorrent)).balanceOf(_msgSender()) > 0;
    }

    function _hasStakeXeNFT() internal view returns (bool) {
        return ERC721(address(xenStake)).balanceOf(_msgSender()) > 0;
    }

    function _getXenftBatch(uint256 tokenId) internal view returns (uint256 batch) {
        require(xenTorrent.ownerOf(tokenId) == _msgSender(), "XONE: not a XENFT owner");
        uint256 mintInfo = xenTorrent.mintInfo(tokenId);
        batch = BATCH_COLLECTOR_XENFT;
        (, bool apex, bool limited) = mintInfo.getClass();
        if (apex) {
            if (tokenId < xenTorrent.specialClassesTokenLimits(6)) {
                if (BATCH_APEX_XUNICORN_XENFT > batch) {
                    batch = BATCH_APEX_XUNICORN_XENFT;
                }
            } else if (tokenId < xenTorrent.specialClassesTokenLimits(5)) {
                if (BATCH_APEX_EXOTIC_XENFT > batch) {
                    batch = BATCH_APEX_EXOTIC_XENFT;
                }
            } else if (tokenId < xenTorrent.specialClassesTokenLimits(4)) {
                if (BATCH_APEX_LEGENDARY_XENFT > batch) {
                    batch = BATCH_APEX_LEGENDARY_XENFT;
                }
            } else if (tokenId < xenTorrent.specialClassesTokenLimits(3)) {
                if (BATCH_APEX_EPIC_XENFT > batch) {
                    batch = BATCH_APEX_EPIC_XENFT;
                }
            } else if (tokenId < xenTorrent.specialClassesTokenLimits(2)) {
                if (BATCH_APEX_RARE_XENFT > batch) {
                    batch = BATCH_APEX_RARE_XENFT;
                }
            }
        } else if (limited && BATCH_LIMITED_XENFT > batch) {
            batch = BATCH_LIMITED_XENFT;
        }
    }

    function _getStakeXenftBatch(uint256 tokenId) internal view returns (uint256 batch) {
        require(xenStake.ownerOf(tokenId) == _msgSender(), "XONE: not a Stake XENFT owner");
        uint256 stakeInfo = xenStake.stakeInfo(tokenId);
        uint256 amount = stakeInfo.getAmount() * 10 ** 18;
        if (amount > XEN_THRESHOLD) {
            batch = BATCH_STAKE_XENFT;
        } else {
            batch = BATCH_FLOOR;
        }
    }

    function _getBatch(uint256 tokenId, bool iStake) internal view returns (uint256 batch) {
        if (tokenId > 0 && _hasXeNFT() && !iStake) {
            batch = _getXenftBatch(tokenId);
        } else if (_hasXENBurns()) {
            batch = BATCH_XEN_BURN;
        } else if (tokenId > 0 && _hasStakeXeNFT() && iStake) {
            batch = _getStakeXenftBatch(tokenId);
        } else if (_hasXENStake()) {
            batch = BATCH_XEN_STAKE;
        } else if (_hasXEN()) {
            batch = BATCH_XEN;
        } else if (_hasVMPX()) {
            batch = BATCH_VMPX;
        } else {
            batch = BATCH_FLOOR;
        }
    }

    function _mint(address account, uint256 amount) internal virtual override (ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function mint(uint256 tokenId, bool isStake) public notBeforeStart {
        require(msg.sender == tx.origin, "XONE: no contract calls");
        require(userMints[_msgSender()] == 0, "XONE: already minted to this address");
        if (tokenId != 0 && !isStake) {
            require(torrentTokensUsed[tokenId] == address(0), "XONE: XENFT already used");
        } else if (tokenId != 0 && isStake) {
            require(stakeTokensUsed[tokenId] == address(0), "XONE: Stake XENFT already used");
        }

        uint256 batch = BATCH_FLOOR;
        batch = _getBatch(tokenId, isStake);
        require(totalSupply() + batch <= cap(), "XONE: minting exceeds cap");
        userMints[_msgSender()] = batch;
        if (tokenId != 0 && !isStake) {
            torrentTokensUsed[tokenId] = _msgSender();
        } else if (tokenId != 0 && isStake) {
            stakeTokensUsed[tokenId] = _msgSender();
        }
        _mint(_msgSender(), batch);
    }

    function burn(address user, uint256 amount) public {
        require(amount > XONE_MIN_BURN, "XONE: Below min limit");
        require(
            IERC165(_msgSender()).supportsInterface(type(IBurnRedeemable).interfaceId),
            "XONE: not a supported contract"
        );

        _spendAllowance(user, _msgSender(), amount);
        _burn(user, amount);
        userBurns[user] += amount;
        IBurnRedeemable(_msgSender()).onTokenBurned(user, amount);
    }
}
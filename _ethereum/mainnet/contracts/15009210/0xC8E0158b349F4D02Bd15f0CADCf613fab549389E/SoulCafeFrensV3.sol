// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";

import "./ICafeStaking.sol";
import "./ICafeAccumulator.sol";
import "./ISudoApprovable.sol";
import "./StakingCommons.sol";
import "./Errors.sol";
import "./Staking.sol";
import "./ERC721LockerUpgradeable.sol";
import "./ProxyRegistry.sol";
import "./UncheckedIncrement.sol";
import "./IERC20StakingLocker.sol";

contract SoulCafeFrensV3 is
    Initializable,
    OwnableUpgradeable,
    ERC721Upgradeable,
    ERC721LockerUpgradeable,
    ICafeAccumulator
{
    using StringsUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AutoStaking for uint256;
    using AutoStaking for StakeAction;
    using AutoStaking for StakeRequest;
    using UncheckedIncrement for uint256;

    event TokenURISet(string indexed uri);
    event PriceUpdate(uint256 indexed newPrice);
    event ContractToggle(bool indexed newState);

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 private constant NEXTANT_ID = MAX_SUPPLY + 1;
    uint256 public constant T1_CAP = 501;
    uint256 public constant T2_CAP = 1001;
    uint256 public constant T3_CAP = 2001;
    uint256 public constant T0_FREN_PRICE = 3000 ether;
    uint256 public constant T1_FREN_PRICE = 3500 ether;
    uint256 public constant T2_FREN_PRICE = 4000 ether;
    uint256 public constant T3_FREN_PRICE = 4800 ether;
    uint256 private constant CAFE_TEAM_SUPPLY = 100;
    address private constant CAFE_TEAM_WALLET = 0x9cD59CD50625C7E2994BA6a2cf9b70c5a775E8db;

    /* ========== STORAGE, APPEND-ONLY ========== */
    bool public paused;
    uint256 public totalSupply;
    uint256 public cafeTeamSupply;
    uint256 internal _stakingTrack;
    ICafeStaking internal _staking;
    IERC20Upgradeable public cafeToken;
    string internal _uri;
    /* V3 */
    bool public allowCAFEUnstaking;

    /* ========== INITIALIZER ========== */

    function initialize(address cafeToken_) external initializer {
        if (!cafeToken_.isContract())
            revert ContractAddressExpected(cafeToken_);

        cafeToken = IERC20Upgradeable(cafeToken_);

        __ERC721_init("Soul Cafe Frens", "SCF");
        __Ownable_init();

        ERC721LockerUpgradeable.__init();
        paused = true;
    }

    /* ========== VIEWS ========== */

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(
        address account,
        uint256 page,
        uint256 records
    ) external view returns (uint256[] memory) {
        uint256 from = page * records;
        uint256 to = (from + records > totalSupply)
            ? totalSupply
            : from + records;
        uint256[] memory found = new uint256[](records);
        uint256 counter;

        for (uint256 t = from; t < to; t = t.inc()) {
            if (account == ownerOf(t)) {
                found[counter] = (t > 0) ? t : NEXTANT_ID;
                counter++;
            }
        }

        uint256[] memory tokenIds = new uint256[](counter);
        for (uint256 t = 0; t < counter; t = t.inc()) {
            if (found[t] > 0) {
                tokenIds[t] = (found[t] == NEXTANT_ID) ? 0 : found[t];
            }
        }

        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert UnknownToken();

        return string(abi.encodePacked(_uri, tokenId.toString(), ".json"));
    }

    function price() external view returns (uint256) {
        return _price();
    }

    function _price() internal view returns (uint256) {
        if (totalSupply < T1_CAP) {
            return T0_FREN_PRICE;
        } else if (totalSupply < T2_CAP) {
            return T1_FREN_PRICE;
        } else if (totalSupply < T3_CAP) {
            return T2_FREN_PRICE;
        } else {
            return T3_FREN_PRICE;
        }
    }

    /* ========== PUBLIC MUTATORS ========== */

    function mint(uint256 qt, bool autostake, bool useStakedCAFE) external {
        _whenNotPaused();
        if (qt == 0) revert ZeroTokensRequested();

        if (totalSupply + qt > MAX_SUPPLY)
            revert MintingExceedsSupply(MAX_SUPPLY);

        uint256 cafeCost = qt * _price();

        uint256 tLocked = IERC20StakingLocker(address(cafeToken)).locked(msg.sender);

        if (cafeToken.balanceOf(msg.sender) - tLocked < cafeCost) {
            _collectRewards();
            if (useStakedCAFE && allowCAFEUnstaking && 
                (cafeToken.balanceOf(msg.sender) - tLocked < cafeCost)) {
                _unstakeCAFE(msg.sender);
            }
        }

        ISudoApprovable(address(cafeToken)).sudoLimitedApprove(
            msg.sender,
            cafeCost
        );
        cafeToken.safeTransferFrom(msg.sender, address(this), cafeCost);

        _mintN(msg.sender, qt);

        if (autostake) {
            _autostake(msg.sender, qt);
        }
    }

    /* ========== ADMIN MUTATORS ========== */

    function configureStaking(address staking, uint256 trackId) external {
        _onlyOwner();
        _setLockerAdmin(staking);
        _staking = ICafeStaking(staking);
        _stakingTrack = trackId;
    }

    function setTokenURI(string memory uri_) external {
        _onlyOwner();
        emit TokenURISet(uri_);
        _uri = uri_;
    }

    function toggle() external {
        _onlyOwner();
        bool newState = !paused;
        emit ContractToggle(newState);
        paused = newState;
    }

    function mintReserve(uint256 qt) external {
        _onlyOwner();
        if (qt == 0) revert ZeroTokensRequested();
        if (cafeTeamSupply + qt > CAFE_TEAM_SUPPLY) revert MintingExceedsSupply(CAFE_TEAM_SUPPLY);
        if (totalSupply + qt > MAX_SUPPLY) revert MintingExceedsSupply(MAX_SUPPLY);
        cafeTeamSupply += qt;
        _mintN(CAFE_TEAM_WALLET, qt);
    }

    function pull(address destination) external returns (uint256) {
        _onlyLockerAdmin();
        address stakingContract = address(_staking);

        if (msg.sender != stakingContract) revert Unauthorized();

        uint256 cafeBalance = cafeToken.balanceOf(address(this));

        cafeToken.safeTransfer(destination, cafeBalance);

        return cafeBalance;
    }

    // V3 -- optionally allow Frens minters to unstake $CAFE
    function toggleAllowCAFEUnstaking() external {
        _onlyOwner();
        allowCAFEUnstaking = !allowCAFEUnstaking;
    }

    /* ========== INTERNALS/MODIFIERS ========== */

    function _mintN(address to, uint256 qt) internal {
        totalSupply += qt;

        for (uint256 t = 0; t < qt; t++) {
            _safeMint(to, totalSupply - qt + t);
        }
    }

    function _autostake(address account, uint256 tokenCount) internal {
        uint256[] memory ids = new uint256[](tokenCount);
        uint256 from = totalSupply - tokenCount;
        uint256 to = totalSupply;
        for (uint256 t = from; t < to; t++) {
            ids[t - from] = t;
        }

        uint256[] memory amounts;

        StakeRequest[] memory msr = StakeRequest(_stakingTrack, ids, amounts)
            .arrayify();

        StakeAction[][] memory actions = new StakeAction[][](1);
        actions[0] = StakeAction.Stake.arrayify();

        _staking.execute4(account, msr, actions);
    }

    function _autounstake(address account, uint256 tokenId) internal {
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        uint256[] memory amounts;
        StakeRequest[] memory msr = StakeRequest(_stakingTrack, ids, amounts).arrayify();

        StakeAction[][] memory actions = new StakeAction[][](1);
        actions[0] = StakeAction.Unstake.arrayify();

        _staking.execute4(account, msr, actions);
    }

    function _unstakeCAFE(address account) internal {
        uint256[] memory empty;
        uint256[] memory amounts = new uint256[](1);
        uint256 CAFE_TRACK_ID = 1;
        amounts[0] = _staking.stakeInfoERC20(CAFE_TRACK_ID, account);
        
        StakeRequest[] memory msr = new StakeRequest[](2);
        msr[0] = StakeRequest(_stakingTrack, empty, empty);
        msr[1] = StakeRequest(CAFE_TRACK_ID, empty, amounts);

        StakeAction[][] memory actions = new StakeAction[][](2);
        actions[0] = StakeAction.Collect.arrayify();
        actions[1] = StakeAction.Unstake.arrayify();

        _staking.execute4(account, msr, actions);
    }

    function _collectRewards() internal {
        uint256 tracks = _staking.tracksCount();
        uint256[] memory empty;

        StakeRequest[] memory msr = new StakeRequest[](tracks);
        StakeAction[][] memory actions = new StakeAction[][](tracks);

        for (uint256 t = 0; t < tracks; t++) {
            msr[t] = StakeRequest(t, empty, empty);
            actions[t] = StakeAction.Collect.arrayify();
        }

        (msr[_stakingTrack], msr[0]) = (msr[0], msr[_stakingTrack]);

        _staking.execute4(msg.sender, msr, actions);
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(OS_PROXY_REGISTRY_ADDRESS);
        if (address(proxyRegistry.proxies(owner_)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        to;
        if (from == address(0)) return;

        if (isLocked(tokenId)) {
            _autounstake(from, tokenId);
        }
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    function _whenNotPaused() internal view {
        if (paused) revert ContractPaused();
    }
}

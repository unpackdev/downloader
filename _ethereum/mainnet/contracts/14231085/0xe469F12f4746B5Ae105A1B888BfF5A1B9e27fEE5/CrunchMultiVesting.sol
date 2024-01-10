// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC20Metadata.sol";

/**
 * @title Crunch Multi Vesting
 * @author Enzo CACERES <enzo.caceres@crunchdao.com>
 * @notice Allow the vesting of multiple users using only one contract.
 */
contract CrunchMultiVesting is Ownable {
    event TokensReleased(
        address indexed beneficiary,
        uint256 index,
        uint256 amount
    );

    event CrunchTokenUpdated(
        address indexed previousCrunchToken,
        address indexed newCrunchToken
    );

    event CreatorChanged(
        address indexed previousAddress,
        address indexed newAddress
    );

    event VestingCreated(
        address indexed beneficiary,
        uint256 amount,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 index
    );

    struct Vesting {
        /* beneficiary of tokens after they are released. */
        address beneficiary;
        /** the amount of token to vest. */
        uint256 amount;
        /** the start time of the token vesting. */
        uint256 start;
        /** the cliff time of the token vesting. */
        uint256 cliff;
        /** the duration of the token vesting. */
        uint256 duration;
        /** the amount of the token released. */
        uint256 released;
    }

    /* CRUNCH erc20 address. */
    IERC20Metadata public crunch;

    /** secondary address that is only allowed to call the `create()` method */
    address public creator;

    /** currently locked tokens that are being used by all of the vestings */
    uint256 public totalSupply;

    /** mapping to vesting list */
    mapping(address => Vesting[]) public vestings;

    /** mapping to a list of the currently active vestings index */
    mapping(address => uint256[]) _actives;

    /**
     * @notice Instanciate a new contract.
     * @dev the creator will be set as the deployer's address.
     * @param _crunch CRUNCH token address.
     */
    constructor(address _crunch) {
        _setCrunch(_crunch);
        _setCreator(owner());
    }

    /**
     * @notice Fake an ERC20-like contract allowing it to be displayed from wallets.
     * @return the contract 'fake' token name.
     */
    function name() external pure returns (string memory) {
        return "Vested CRUNCH Token (multi)";
    }

    /**
     * @notice Fake an ERC20-like contract allowing it to be displayed from wallets.
     * @return the contract 'fake' token symbol.
     */
    function symbol() external pure returns (string memory) {
        return "mvCRUNCH";
    }

    /**
     * @notice Fake an ERC20-like contract allowing it to be displayed from wallets.
     * @return the crunch's decimals value.
     */
    function decimals() external view returns (uint8) {
        return crunch.decimals();
    }

    /**
     * @notice Create a new vesting.
     *
     * Requirements:
     * - caller must be the owner or the creator
     * - `amount` must not be zero
     * - `beneficiary` must not be the null address
     * - `cliffDuration` must be less than the duration
     * - `duration` must not be zero
     * - there must be enough available reserve to accept the amount
     *
     * @dev A `VestingCreated` event will be emitted.
     * @param beneficiary Address that will receive CRUNCH tokens.
     * @param amount Amount of CRUNCH to vest.
     * @param cliffDuration Cliff duration in seconds.
     * @param duration Vesting duration in seconds.
     */
    function create(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 duration
    ) external onlyCreatorOrOwner {
        require(
            beneficiary != address(0),
            "MultiVesting: beneficiary is the zero address"
        );

        require(amount > 0, "MultiVesting: amount is 0");

        require(duration > 0, "MultiVesting: duration is 0");

        require(
            cliffDuration <= duration,
            "MultiVesting: cliff is longer than duration"
        );

        require(
            availableReserve() >= amount,
            "MultiVesting: available reserve is not enough"
        );

        uint256 start = block.timestamp;
        uint256 cliff = start + cliffDuration;

        vestings[beneficiary].push(
            Vesting({
                beneficiary: beneficiary,
                amount: amount,
                start: start,
                cliff: cliff,
                duration: duration,
                released: 0
            })
        );

        uint256 index = vestings[beneficiary].length - 1;
        _actives[beneficiary].push(index);

        totalSupply += amount;

        emit VestingCreated(beneficiary, amount, start, cliff, duration, index);
    }

    /**
     * @notice Get the current reserve (or balance) of the contract in CRUNCH.
     * @return The balance of CRUNCH this contract has.
     */
    function reserve() public view returns (uint256) {
        return crunch.balanceOf(address(this));
    }

    /**
     * @notice Get the available reserve.
     * @return The number of CRUNCH that can be used to create another vesting.
     */
    function availableReserve() public view returns (uint256) {
        return reserve() - totalSupply;
    }

    /**
     * @notice Release a vesting of the current caller by its `index`.
     * @dev A `TokensReleased` event will be emitted.
     * @dev The transaction will fail if no token are due.
     * @param index The vesting index to release.
     */
    function release(uint256 index) external {
        _release(_msgSender(), index);
    }

    /**
     * @notice Release a vesting of a specified address by its `index`.
     * @dev The caller must be the owner.
     * @param beneficiary Address to release.
     * @param index The vesting index to release.
     */
    function releaseFor(address beneficiary, uint256 index) external onlyOwner {
        _release(beneficiary, index);
    }

    /**
     * @notice Release all of active vesting of the current caller.
     * @dev Multiple `TokensReleased` event might be emitted.
     * @dev The transaction will fail if no token are due.
     */
    function releaseAll() external {
        _releaseAll(_msgSender());
    }

    /**
     * @notice Release all of active vesting of a specified address.
     * @dev Multiple `TokensReleased` event might be emitted.
     * @dev The transaction will fail if no token are due.
     */
    function releaseAllFor(address beneficiary) external onlyOwner {
        _releaseAll(beneficiary);
    }

    /**
     * @notice Get the total of releasable amount of tokens by doing the sum of all of the currently active vestings.
     * @param beneficiary Address to check.
     * @return total The sum of releasable amounts.
     */
    function releasableAmount(address beneficiary)
        public
        view
        returns (uint256 total)
    {
        uint256 size = vestingsCount(beneficiary);

        for (uint256 index = 0; index < size; index++) {
            Vesting storage vesting = _getVesting(beneficiary, index);

            total += _releasableAmount(vesting);
        }
    }

    /**
     * @notice Get the releasable amount of tokens of a vesting by its `index`.
     * @param beneficiary Address to check.
     * @param index Vesting index to check.
     * @return The releasable amount of tokens of the found vesting.
     */
    function releasableAmountAt(address beneficiary, uint256 index)
        external
        view
        returns (uint256)
    {
        Vesting storage vesting = _getVesting(beneficiary, index);

        return _releasableAmount(vesting);
    }

    /**
     * @notice Get the sum of all vested amount of tokens.
     * @param beneficiary Address to check.
     * @return total The sum of vested amount of all of the vestings.
     */
    function vestedAmount(address beneficiary) public view returns (uint256 total) {
        uint256 size = vestingsCount(beneficiary);

        for (uint256 index = 0; index < size; index++) {
            Vesting storage vesting = _getVesting(beneficiary, index);

            total += _vestedAmount(vesting);
        }
    }

    /**
     * @notice Get the vested amount of tokens of a vesting by its `index`.
     * @param beneficiary Address to check.
     * @param index Address to check.
     * @return The vested amount of the found vesting.
     */
    function vestedAmountAt(address beneficiary, uint256 index)
        external
        view
        returns (uint256)
    {
        Vesting storage vesting = _getVesting(beneficiary, index);

        return _vestedAmount(vesting);
    }

    /**
     * @notice Get the sum of all remaining amount of tokens of each vesting of a beneficiary.
     * @dev This function is to make wallets able to display the amount in their UI.
     * @param beneficiary Address to check.
     * @return total The sum of all remaining amount of tokens.
     */
    function balanceOf(address beneficiary) external view returns (uint256 total) {
        uint256 size = vestingsCount(beneficiary);

        for (uint256 index = 0; index < size; index++) {
            Vesting storage vesting = _getVesting(beneficiary, index);

            total += vesting.amount - vesting.released;
        }
    }

    /**
     * @notice Update the CRUNCH token address.
     * @dev The caller must be the owner.
     * @dev A `CrunchTokenUpdated` event will be emitted.
     * @param newCrunch New CRUNCH token address.
     */
    function setCrunch(address newCrunch) external onlyOwner {
        _setCrunch(newCrunch);
    }

    /**
     * @notice Update the creator address. The old address will no longer be able to access the `create(...)` method.
     * @dev The caller must be the owner.
     * @dev A `CreatorChanged` event will be emitted.
     * @param newCreator New creator address.
     */
    function setCreator(address newCreator) external onlyOwner {
        _setCreator(newCreator);
    }

    /**
     * @notice Get the number of vesting of an address.
     * @param beneficiary Address to check.
     * @return Number of vesting.
     */
    function vestingsCount(address beneficiary) public view returns (uint256) {
        return vestings[beneficiary].length;
    }

    /**
     * @notice Get the number of active vesting of an address.
     * @param beneficiary Address to check.
     * @return Number of active vesting.
     */
    function activeVestingsCount(address beneficiary)
        public
        view
        returns (uint256)
    {
        return _actives[beneficiary].length;
    }

    /**
     * @notice Get the active vestings index.
     * @param beneficiary Address to check.
     * @return An array of currently active vestings index.
     */
    function activeVestingsIndex(address beneficiary)
        external
        view
        returns (uint256[] memory)
    {
        return _actives[beneficiary];
    }

    /**
     * @dev Internal implementation of the release() method.
     * @dev The methods will fail if there is no tokens due.
     * @dev A `TokensReleased` event will be emitted.
     * @dev If the vesting's released tokens is the same of the vesting's amount, the vesting is considered as finished, and will be removed from the active list.
     * @param beneficiary Address to release.
     * @param index Vesting index to release.
     */
    function _release(address beneficiary, uint256 index) internal {
        Vesting storage vesting = _getVesting(beneficiary, index);

        uint256 unreleased = _releasableAmount(vesting);
        require(unreleased > 0, "MultiVesting: no tokens are due");

        vesting.released += unreleased;

        crunch.transfer(vesting.beneficiary, unreleased);

        totalSupply -= unreleased;

        emit TokensReleased(vesting.beneficiary, index, unreleased);

        if (vesting.released == vesting.amount) {
            _removeActive(beneficiary, index);
        }
    }

    /**
     * @dev Internal implementation of the releaseAll() method.
     * @dev The methods will fail if there is no tokens due for all of the vestings.
     * @dev Multiple `TokensReleased` event may be emitted.
     * @dev If some vesting's released tokens is the same of their amount, they will considered as finished, and will be removed from the active list.
     * @param beneficiary Address to release.
     */
    function _releaseAll(address beneficiary) internal {
        uint256 totalReleased;

        uint256[] storage actives = _actives[beneficiary];
        for (uint256 activeIndex = 0; activeIndex < actives.length; ) {
            uint256 index = actives[activeIndex];
            Vesting storage vesting = _getVesting(beneficiary, index);

            uint256 unreleased = _releasableAmount(vesting);
            if (unreleased == 0) {
                activeIndex++;
                continue;
            }

            vesting.released += unreleased;
            totalSupply -= unreleased;

            crunch.transfer(vesting.beneficiary, unreleased);

            emit TokensReleased(vesting.beneficiary, index, unreleased);

            if (vesting.released == vesting.amount) {
                _removeActiveAt(beneficiary, activeIndex);
            } else {
                activeIndex++;
            }

            totalReleased += unreleased;
        }

        require(totalReleased > 0, "MultiVesting: no tokens are due");
    }

    /**
     * @dev Pop from the active list at a specified index.
     * @param beneficiary Address to get the active list from.
     * @param activeIndex Active list's index to pop.
     */
    function _removeActiveAt(address beneficiary, uint256 activeIndex) internal {
        uint256[] storage actives = _actives[beneficiary];

        actives[activeIndex] = actives[actives.length - 1];

        actives.pop();
    }

    /**
     * @dev Find the active index of a vesting index, and pop it with `_removeActiveAt(address, uint256)`.
     * @dev The method will fail if the active index is not found.
     * @param beneficiary Address to get the active list from.
     * @param index Vesting index to find and pop.
     */
    function _removeActive(address beneficiary, uint256 index) internal {
        uint256[] storage actives = _actives[beneficiary];

        for (
            uint256 activeIndex = 0;
            activeIndex < actives.length;
            activeIndex++
        ) {
            if (actives[activeIndex] == index) {
                _removeActiveAt(beneficiary, activeIndex);
                return;
            }
        }

        revert("MultiVesting: active index not found");
    }

    /**
     * @dev Compute the releasable amount.
     * @param vesting Vesting instance.
     */
    function _releasableAmount(Vesting memory vesting)
        internal
        view
        returns (uint256)
    {
        return _vestedAmount(vesting) - vesting.released;
    }

    /**
     * @dev Compute the vested amount.
     * @param vesting Vesting instance.
     */
    function _vestedAmount(Vesting memory vesting)
        internal
        view
        returns (uint256)
    {
        uint256 amount = vesting.amount;

        if (block.timestamp < vesting.cliff) {
            return 0;
        } else if ((block.timestamp >= vesting.start + vesting.duration)) {
            return amount;
        } else {
            return
                (amount * (block.timestamp - vesting.start)) / vesting.duration;
        }
    }

    /**
     * @dev Get a vesting.
     * @param beneficiary Address to get it from.
     * @param index Index to get it from.
     * @return A vesting struct stored in the storage.
     */
    function _getVesting(address beneficiary, uint256 index)
        internal
        view
        returns (Vesting storage)
    {
        return vestings[beneficiary][index];
    }

    /**
     * @dev Update the CRUNCH token address.
     * @dev A `CrunchTokenUpdated` event will be emitted.
     * @param newCrunch New CRUNCH token address.
     */
    function _setCrunch(address newCrunch) internal {
        address previousCrunch = address(crunch);

        crunch = IERC20Metadata(newCrunch);

        emit CrunchTokenUpdated(previousCrunch, address(newCrunch));
    }

    /**
     * @dev Update the creator address.
     * @dev A `CreatorChanged` event will be emitted.
     * @param newCreator New creator address.
     */
    function _setCreator(address newCreator) internal {
        address previous = creator;

        creator = newCreator;

        emit CreatorChanged(previous, newCreator);
    }

    /**
     * @dev Ensure that the caller is the creator or the owner.
     */
    modifier onlyCreatorOrOwner() {
        require(
            _msgSender() == creator || _msgSender() == owner(),
            "MultiVesting: only creator or owner can do this"
        );
        _;
    }
}

// contracts/Box.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";

/**
 * @title IncompleteControlPowah
 * @author DefiJesus
 *
 * An ERC20 token used for tracking the ownership count of incomplete control pieces.
 * This contract is inspired by SetProtocol's IndexPowah contract and
 * Sushiswap's SUSHIPOWAH contract which serves the same purpose.
 */
contract IncompleteControlPowah is IERC20, IERC20Metadata, Ownable {

    uint256 public abRangeMin;
    uint256 public abRangeMax;
    address public abAddress;

    /**
     * @param _min  min Artblocks Range
     * @param _max  max ArtBlocks Range
     * @param _address ArtBlocks SC address
     */
    constructor(
        uint256 _min,
        uint256 _max,
        address _address
    )
    {
        require(_max >= _min, "Max must be greater than or equal to min.");
        abRangeMin = _min;
        abRangeMax = _max;
        abAddress = _address;
    }

    function configure(uint256 _min, uint256 _max, address _address) public onlyOwner {
        require(_max >= _min, "Max must be greater than or equal to min.");
        abRangeMin = _min;
        abRangeMax = _max;
        abAddress = _address;
    }

    /**
     * Computes an address's balance of incomplete control pieces.
     *
     * Balances can not be transfered in the traditional way, but are instead
     * computed by the amount of ArtBlocks tokens that an account directly
     * holds.
     *
     * @param _account  the address of the owner
     */
    function balanceOf(address _account) public view override returns (uint256) {
        uint256[] memory blocks = ArtBlocks(abAddress).tokensOfOwner(_account);
        uint256 counter = 0;

         for (uint256 i=0; i < blocks.length; i++) {
            if (blocks[i] >= abRangeMin && blocks[i] <= abRangeMax) {
                counter++;
            }
         }

        return counter;
    }

    function name() public pure override returns (string memory) {
        return "INCOMPLETE CONTROL POWAH";
    }

    function symbol() public pure override returns (string memory) {
        return "INCOMPLETE CONTROL POWAH";
    }

    function decimals() public pure override returns(uint8) {
        return 0;
    }

    function totalSupply() public view override returns (uint256) {
        assert(abRangeMax >= abRangeMin);
        return abRangeMax - abRangeMin + 1;
    }

    function allowance(address, address) public pure override returns (uint256) {
        return 0;
    }

    function transfer(address, uint256) public pure override returns (bool) {
        return false;
    }

    function approve(address, uint256) public pure override returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        return false;
    }
}

interface ArtBlocks {
    function tokensOfOwner(address owner) external view returns(uint256[] calldata);
    function totalSupply() external view returns (uint256);
}

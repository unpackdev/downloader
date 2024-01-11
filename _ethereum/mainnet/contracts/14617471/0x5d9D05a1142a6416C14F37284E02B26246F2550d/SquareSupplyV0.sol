// SPDX-License-Identifier: UNLICENSED
/*
* ░██████╗░██████╗░██╗░░░██╗░█████╗░██████╗░███████╗░██████╗██╗░░░██╗██████╗░██████╗░██╗░░░░░██╗░░░██╗░░░██╗░░██╗██╗░░░██╗███████╗
* ██╔════╝██╔═══██╗██║░░░██║██╔══██╗██╔══██╗██╔════╝██╔════╝██║░░░██║██╔══██╗██╔══██╗██║░░░░░╚██╗░██╔╝░░░╚██╗██╔╝╚██╗░██╔╝╚════██║
* ╚█████╗░██║██╗██║██║░░░██║███████║██████╔╝█████╗░░╚█████╗░██║░░░██║██████╔╝██████╔╝██║░░░░░░╚████╔╝░░░░░╚███╔╝░░╚████╔╝░░░███╔═╝
* ░╚═══██╗╚██████╔╝██║░░░██║██╔══██║██╔══██╗██╔══╝░░░╚═══██╗██║░░░██║██╔═══╝░██╔═══╝░██║░░░░░░░╚██╔╝░░░░░░██╔██╗░░░╚██╔╝░░██╔══╝░░
* ██████╔╝░╚═██╔═╝░╚██████╔╝██║░░██║██║░░██║███████╗██████╔╝╚██████╔╝██║░░░░░██║░░░░░███████╗░░░██║░░░██╗██╔╝╚██╗░░░██║░░░███████╗
* ╚═════╝░░░░╚═╝░░░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝░░░░░╚══════╝░░░╚═╝░░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝
*/
pragma solidity ^0.8.9;

// @openzeppelin {{{
import "./IERC20.sol";

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Initializable.sol";
/*import "./UUPSUpgradeable.sol";*/

import "./Strings.sol";
import "./SafeMath.sol";

import "./Counters.sol";
import "./Address.sol";
import "./SafeERC20.sol";
// @openzeppelin }}}

// @uniswap {{{
import "./ISwapRouter.sol";
import "./TransferHelper.sol";
// @uniswap }}}

// dev {{{
/*import "./EffuPami.sol";*/
/*import "./ShuffleYield.sol";*/
import "./console.sol";
// dev }}}


contract SquareSupplyV0 is
Initializable,
ERC1155,
Ownable,
Pausable,
ERC1155Burnable,
ERC1155Supply
/*UUPSUpgradeable*/
{
    // class overloads {{{
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using Address for address payable;
    // class overloads }}}

    // class vars {{{
    string public name;
    string public symbol;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    //uint256 public cornersRemaining;
    Counters.Counter public cornersRemaining;

    mapping(uint256 => uint256) private _movedCorners;

    string private baseURI;
    string private baseExtension;

    mapping(uint256 => uint256) public costs;

    // uniswap-v3
    ISwapRouter public swapRouter;
    uint24[3] public poolFees = [500, 3000, 10000];
    address public wETH;
    // class vars }}}

    // constructor {{{
    /*function initialize(*/
    constructor(
        string memory _baseURI,
        ISwapRouter _swapRouter,
        address _weth
    ) ERC1155("ipfs://QmTz1aAoS6MXfHpGZpJ9YAGH5wrDsAteN8UHmkHMxVoNJk/") {
        name             = "Square Supply Corners";
        symbol           = "CORNER";
        maxSupply        = 10*1000;
        maxMintAmount    = 4;

        cornersRemaining = Counters.Counter({_value: maxSupply});

        baseURI          = _baseURI;
        baseExtension    = ".json";

        swapRouter = _swapRouter;
        wETH = _weth;

        costs[1]     = 0.042 ether; // ethereum (mainnet)
        costs[4]     = 0.042 ether; // rinkeby (testnet)
        costs[137]   = 0.001 ether; // matic (mainnet) [polygon]
        costs[80001] = 0.001 ether; // mumbai (testnet) [polygon]
        costs[31337] = 0.042 ether; // localhost (devnet) [hardhat]
        cost = costs[block.chainid];
        require(cost > 0, "invalid costs[block.chainid]");
    }
    // constructor }}}

    // standard erc1155 stuff {{{
    function uri(uint256 _tokenId) public view override virtual returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString(), baseExtension));
    }

    function pause() public onlyOwner { _pause(); }

    function unpause() public onlyOwner { _unpause(); }

    // Unused.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    // standard erc1155 stuff }}}

    // uups {{{
    /*function _authorizeUpgrade(address) internal view override onlyOwner { return; }*/
    // uups }}}

    // admin mint {{{
    // The owner may mint any unminted corner.
    function mint(address _to, uint256 _id) external onlyOwner {
        require(totalSupply(_id) == 0, "corner already minted");
        require(cornersRemaining.current() > 0, "no corners remain");
        _reserveCorner(_id);
        _mint(_to, _id, 1, "0x00");
    }

    // The owner may mint any unminted corners (multiple ids at once).
    function mintBatch(address _to, uint[] memory _ids) external onlyOwner {
        require(_ids.length <= cornersRemaining.current(), "fewer corners remain");
        uint256[] memory _amounts = new uint256[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            require(totalSupply(_ids[i]) == 0, "a corner is already minted");
            _reserveCorner(_ids[i]);
            _amounts[i] = 1;
        }
        _mintBatch(_to, _ids, _amounts, "0x00");
    }
    // admin mint }}}

    // admin withdraw {{{
    // The owner may withdraw all the funds.
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "need eth to withdraw");
        payable(owner()).transfer(address(this).balance);
    }

    // The owner may withdraw some of the funds.
    function withdraw(uint amount) external onlyOwner {
        require(address(this).balance > 0, "need eth to withdraw");
        require(amount <= address(this).balance, "don't have that much");
        payable(owner()).transfer(amount);
    }

    // The owner may withdraw any ERC20 token.
    function withdraw(IERC20 _token, uint256 _amount) public onlyOwner {
        uint256 tokenBalance = _token.balanceOf(address(this));
        require(tokenBalance > 0, "need balance to withdraw");
        require(_amount <= tokenBalance, "don't have that much");
        /*_token.safeApprove(address(this), tokenBalance);*/
        _token.safeTransfer(msg.sender, tokenBalance);
        /*TransferHelper.safeTransferFrom(address(_token), address(this), msg.sender, _amount);*/
    }

    // The owner may withdraw wETH.
    function withdrawWeth() external onlyOwner {
        uint256 _wethBalance = IERC20(wETH).balanceOf(address(this));
        withdraw(IERC20(wETH), _wethBalance);
    }

    // The owner may withdraw wETH.
    function withdrawWeth(uint256 _amount) external onlyOwner {
        withdraw(IERC20(wETH), _amount);
    }
    // admin withdraw }}}

    // PRIVATE mint logic {{{
    function _requireEnoughSupply(uint256 _howMany) private view {
        require(_howMany <= maxMintAmount, "too many corners at once");
        require(_howMany <= cornersRemaining.current(), "fewer corners remain");
    }

    function _mintCornerSafe(uint256 _howMany) private {
        _requireEnoughSupply(_howMany);
        _mintCorners(_howMany);
    }

    // Private internal mint interface (single or batch ~ ooh lala).
    function _mintCorners(uint256 _howMany) private {
        if (_howMany == 1) {
            _mintCorner();
        } else {
            _mintCorner(_howMany);
        }
    }

    function _requireIdUnminted(uint256 _cornerId) private view {
        require(totalSupply(_cornerId) == 0, "id already minted");
    }

    // Private mint single interface.
    function _mintCorner() private {
        uint256 newCornerId = _reserveRandomCorner();
        _requireIdUnminted(newCornerId);
        _mint(msg.sender, newCornerId, 1, "0x00");
    }

    // Private mint plural interface.
    function _mintCorner(uint256 _howMany) private {
        uint256[] memory _ids     = new uint256[](_howMany);
        uint256[] memory _amounts = new uint256[](_howMany);
        for (uint256 i = 0; i < _howMany; i++) {
            _ids[i]     = _reserveRandomCorner();
            _amounts[i] = 1;
            _requireIdUnminted(_ids[i]);
        }
        _mintBatch(msg.sender, _ids, _amounts, "0x00");
    }
    // PRIVATE mint logic }}}

    // PUBLIC mint logic {{{
    // The number of corners that have been minted so far.
    function mintedCorners() external view returns (uint256) {
        return maxSupply - cornersRemaining.current();
    }

    // !! This is the public pay-wall that charges eth to mint !!
    // The owner may bypass important checks like payment and the max mint amount.
    function mintCornerWithETH(uint256 _howMany) external payable {
        require(cost * _howMany == msg.value, "insufficient ETH");
        _mintCornerSafe(_howMany);
    }

    // !! This is the public pay-wall that swaps ERC20 tokens to wETH for payment!!
    // You may pay to mint with any token that Uniswap supports via this.
    function mintCornerWithToken(uint256 _howMany, address _paymentToken, uint256 _paymentMax, uint256 _poolFee) external {
        // do the requires before the swap so we don't waste gas and time i think idk
        _requireEnoughSupply(_howMany);
        _swapExactOutputSingle(_paymentToken, _paymentMax, _howMany, _poolFee);
        _mintCorners(_howMany);
    }
    // PUBLIC mint logic }}}

    // pseudo-random minting logic (fischer-yates shuffle) {{{
    // A very strange shuffle algorithm takes place over a long time, during mint.
    // The code is all inside this {{{.*}}} thingy, so pay attention.
    // INFO: derived from [REDACTED]

    // Sort-of-random-enough data
    //
    // To be succeeded by lmaoRandom()
    function _lolRandom() private view returns (uint) {
        // solhint-disable-next-line not-rely-on-time, no-block-members
        uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        return randomHash;
    }
    //
    // returns a random value in [0, max)
    function _lolRandom(uint256 max) private view returns (uint256) {
        return _lolRandom() % max;
    }

    // NOTE: Unintialized data is non-zero in the evm/solidity lol..
    // _movedCorners is an unintuitive data structure;
    // run a few small-batch mints and examine this function's output!
    function _cornerAt(uint256 i) private view returns (uint256) {
        if (_movedCorners[i] != 0) {
            return _movedCorners[i];
        }
        return i;
    }

    // Draw a random "card" from the "deck", swap it with the last card, and
    // shorten the search window by one, to avoid repeats. This is O(1)
    // apparently lol.. (^ this really is all there is to it)
    function _reserveRandomCorner() private returns (uint256) {
        require(cornersRemaining.current() > 0, "all corners minted");
        uint256 i = _lolRandom(cornersRemaining.current()); // Pick a random i from 0<->cornersRemaining
        uint256 outCorner = _cornerAt(i);                   // Pick the i'th "card" in the range or "deck"
        _reserveCorner(i);                                  // Reserve the corner, exclude from now on.
        return outCorner;
    }

    // This function, along with _cornerAt(uint256), does the O(1) magic.
    function _reserveCorner(uint256 i) private {
        // Swap the i'th corner with the last-most one.
        _movedCorners[i] = _cornerAt(cornersRemaining.current() - 1);
        _movedCorners[cornersRemaining.current() - 1] = 0;
        // Exclude the i'th corner from future picks.
        cornersRemaining.decrement();
    }

    // :wave: byeee!!
    // pseudo-random minting }}}

    // magic uniswap payments {{{
    /// @notice _swapExactOutputSingle swaps a *minimum possible amount of _paymentToken* for a _fixed amount of wETH_.
    /// @dev The calling address must approve this contract to spend its _paymentToken for this function
    ///   to succeed. As the amount of input _paymentToken is variable, the calling address will
    ///   need to approve for a slightly higher amount, anticipating some variance.
    /// @param _paymentToken The address of the token to swap to wETH to pay with.
    /// @param _paymentMax The amount of _paymentToken we are willing to spend to receive the specified amount of wETH.
    /// @return payment The amount of _paymentToken actually spent in the swap.
    function _swapExactOutputSingle(address _paymentToken, uint256 _paymentMax, uint256 _numToMint, uint _poolFee)
        private
        returns (uint256 payment)
    {
        TransferHelper.safeTransferFrom(_paymentToken, msg.sender, address(this), _paymentMax);
        TransferHelper.safeApprove(_paymentToken, address(swapRouter), _paymentMax);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: _paymentToken,
                tokenOut: wETH,
                fee: poolFees[_poolFee],
                /*recipient: msg.sender,*/
                recipient: address(this),
                deadline: block.timestamp,
                // just ask for what you want,
                // while offering up what you will:
                amountOut: cost * _numToMint,
                amountInMaximum: _paymentMax,
                sqrtPriceLimitX96: 0
            });

        payment = swapRouter.exactOutputSingle(params);

        // For 'exact output' swaps, the _paymentMax may not have all been spent.
        if (payment < _paymentMax) {
            TransferHelper.safeApprove(_paymentToken, address(swapRouter), 0);
            TransferHelper.safeTransfer(_paymentToken, msg.sender, _paymentMax - payment);
        }
    }
    //}}}
}

// vim: set fdm=marker:

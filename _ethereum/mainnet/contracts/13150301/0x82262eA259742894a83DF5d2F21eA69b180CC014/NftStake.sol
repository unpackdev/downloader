// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IERC721.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";

contract NftStake is IERC721Receiver, ReentrancyGuard {
    using SafeMath for uint256;

    IERC721 public nftToken;
    IERC20 public erc20Token;

    string public constant TERMS_OF_SERVICE =
        'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.';

    address public admin;
    uint256 public emissionRate;

    struct Stake {
        uint256 from;
        address owner;
    }

    // TokenID => Stake
    mapping(uint256 => Stake) public receipt;

    event Staked(address indexed staker, uint256 tokenId, uint256 block);
    event Unstaked(address indexed staker, uint256 tokenId, uint256 block);
    event Payout(address indexed staker, uint256 tokenId, uint256 amount, uint256 fromBlock, uint256 toBlock);
    event EmissionRateUpdate(uint256 rate);

    modifier onlyStaker(uint256 tokenId) {
        // require that this contract has the NFT
        require(nftToken.ownerOf(tokenId) == address(this), "nftstake: not owned");

        // require that this token is staked
        require(receipt[tokenId].from != 0, "nftstake: not staked");

        // require that msg.sender is the owner of this nft
        require(receipt[tokenId].owner == msg.sender, "nftstake: not owner");

        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "nftstake: not admin");
        _;
    }

    modifier acceptedTermsOfService(bool accepted) {
        require(accepted, "nftstake: must accept terms of service");
        _;
    }

    constructor(
        IERC721 _nftToken,
        IERC20 _erc20Token,
        address _admin,
        uint256 _emissionRate
    ) {
        nftToken = _nftToken;
        erc20Token = _erc20Token;
        admin = _admin;
        emissionRate = _emissionRate;

        emit EmissionRateUpdate(emissionRate);
    }

    // User must give this contract permission to take ownership of it.
    function stake(uint256[] calldata ids, bool iAcceptTermOfService)
        public
        nonReentrant
        acceptedTermsOfService(iAcceptTermOfService)
        returns (bool)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            _stake(ids[i]);
        }
        return true;
    }

    function unstake(uint256[] calldata ids, bool iAcceptTermOfService)
        public
        nonReentrant
        acceptedTermsOfService(iAcceptTermOfService)
        returns (bool)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            _unstake(ids[i]);
        }
        return true;
    }

    function harvest(uint256[] calldata ids, bool iAcceptTermOfService)
        public
        nonReentrant
        acceptedTermsOfService(iAcceptTermOfService)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            _harvest(ids[i]);
        }
    }

    function sweep() external {
        erc20Token.transfer(admin, erc20Token.balanceOf(address(this)));
    }

    function _stake(uint256 tokenId) internal returns (bool) {
        receipt[tokenId].from = block.number;
        receipt[tokenId].owner = msg.sender;
        nftToken.safeTransferFrom(msg.sender, address(this), tokenId);
        emit Staked(msg.sender, tokenId, block.number);
        return true;
    }

    function _unstake(uint256 tokenId) internal onlyStaker(tokenId) returns (bool) {
        if (receipt[tokenId].from < block.number) {
            // payout stake, this should be safe as the function is non-reentrant
            _payout(tokenId);
        }

        delete receipt[tokenId];
        nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Unstaked(msg.sender, tokenId, block.number);
        return true;
    }

    function _harvest(uint256 tokenId) internal onlyStaker(tokenId) {
        require(receipt[tokenId].from < block.number, "nftstake: too soon");

        // payout stake, this should be safe as the function is non-reentrant
        _payout(tokenId);
        receipt[tokenId].from = block.number;
    }

    function _payout(uint256 tokenId) internal {
        /* NOTE : Must be called from non-reentrant function to be safe!*/
        require(receipt[tokenId].from != 0, "nftstake: not staked");

        // earned amount is difference between the stake start block, current block multiplied by stake amount
        uint256 duration = block.number.sub(receipt[tokenId].from).sub(1); // don't pay for the tx block of withdrawl
        uint256 reward = duration.mul(emissionRate);

        // If contract does not have enough tokens to pay out, return the NFT without payment
        // This prevent a NFT being locked in the contract when empty
        if (erc20Token.balanceOf(address(this)) < reward) {
            emit Payout(msg.sender, tokenId, 0, receipt[tokenId].from, block.number);
            return;
        }

        erc20Token.transfer(receipt[tokenId].owner, reward);

        emit Payout(msg.sender, tokenId, reward, receipt[tokenId].from, block.number);
    }

    function rewardOf(uint256 tokenId) public view returns (uint256) {
        if (receipt[tokenId].from == 0) {
            return 0;
        }

        return block.number.sub(receipt[tokenId].from).mul(emissionRate);
    }

    function setEmissionRate(uint256 _emissionRate) external onlyAdmin {
        emissionRate = _emissionRate;
        emit EmissionRateUpdate(emissionRate);
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /** Add Function to allow the DAO to forcibly unstake an NFT and return it to the owner */
}

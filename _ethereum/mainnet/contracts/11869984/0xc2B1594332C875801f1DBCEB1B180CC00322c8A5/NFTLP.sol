// // SPDX-License-Identifier: MIT
// pragma solidity ^0.6.0;

// import "./Counters.sol";
// import "./IERC20.sol";
// import "./SafeERC20.sol";
// import "./SafeMath.sol";

// import "./ERC721.sol";
// import "./ERC721Burnable.sol";

// contract NFTLP is ERC721Burnable {
//     using SafeMath for uint256;
//     using SafeERC20 for IERC20;

//     using Counters for Counters.Counter;

//     Counters.Counter private _tokenIdTracker;

//     struct NFTDetails {
//         address erc20address; //Address of LP token contract
//         uint256 amount; // amount lp tokens staked
//         uint256 block; //block the nft was minted at
//     }

//     mapping(uint256 => NFTDetails) private nftDetails;

//     // total staked per token address
//     mapping(address => uint256) public totalStaked;

//     constructor(string memory baseURI_) public ERC721("NFT20", "NFT20") {
//         _setBaseURI(baseURI_);
//     }

//     function getNFTInfo(uint256 _nftId)
//         public
//         view
//         returns (
//             address _erc20address,
//             uint256 _amount,
//             uint256 _block
//         )
//     {
//         NFTDetails storage nft = nftDetails[_nftId];
//         _erc20address = nft.erc20address;
//         _amount = nft.amount;
//         _block = nft.block;
//     }

//     // deposit LP tokens and get NFT representation
//     function deposit(address erc20address, uint256 amount) external {
//         // deposit lp tokens into contract
//         IERC20(erc20address).safeTransferFrom(
//             address(msg.sender),
//             address(this),
//             amount
//         );

//         nftDetails[_tokenIdTracker.current()] = NFTDetails(
//             erc20address,
//             amount,
//             block.number
//         );

//         totalStaked[erc20address] = totalStaked[erc20address].add(amount);

//         // give minter role to this contract
//         _mint(msg.sender, _tokenIdTracker.current());

//         _tokenIdTracker.increment();
//     }

//     // instead of withdraw I am overriding the burn function from NFTs.
//     // this is because if there was withdraw and someone executes burn, it would burn the token and
//     // not delete the struct or make blance go down or send LP tokens back.
//     // not sure about this let me know.
//     function burn(uint256 tokenId) public override {
//         //solhint-disable-next-line max-line-length
//         require(
//             _isApprovedOrOwner(_msgSender(), tokenId),
//             "ERC721Burnable: caller is not owner nor approved"
//         );

//         NFTDetails storage nft = nftDetails[tokenId];

//         totalStaked[nft.erc20address] = totalStaked[nft.erc20address].sub(
//             nft.amount
//         );

//         // Send lp tokens to user
//         IERC20(nft.erc20address).transfer(msg.sender, nft.amount);

//         // delete data
//         delete nftDetails[tokenId];
//         _burn(tokenId);
//     }




// // SPDX-License-Identifier: AGPL-3.0-or-later
// pragma solidity ^0.6.8;
// pragma experimental ABIEncoderV2;

// import "./ReentrancyGuard.sol";
// import "./SafeERC20.sol";
// import "./IERC721.sol";
// import "./IERC721Receiver.sol";
// import "./IERC1155.sol";
// import "./ERC1155Receiver.sol";

// contract MultiAssetSwapper is ReentrancyGuard, ERC1155Receiver, IERC721Receiver {

//   using SafeERC20 for IERC20;
//   using SafeMath for uint256;

//   struct Swap {
//     address proposer;
//     address[] tokenAddresses;
//     uint256[] amounts;
//     uint256[] ids;
//     bool[] isERC20;
//     // 0 to (numToSwapFor-1) are the proposer's assets
//     // numToSwapFor to (tokenAddresses.length-1) are the desired assets
//     uint256 numToSwapFor;
//   }

  

//   uint256 public currSwapIndex;
//   mapping(uint256 => Swap) swapRecords;

//   constructor() public {}

//   // Accepts safe ERC-721 transfers
//   function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
//     return this.onERC721Received.selector;
//   }

//   // From: https://docs.gnosis.io/conditionaltokens/docs/ctftutorial13/
//   function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns(bytes4) {
//       return this.onERC1155BatchReceived.selector;
//   }

//   function onERC1155BatchReceived( address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data )
//   external override returns(bytes4) {
//         return this.onERC1155BatchReceived.selector;
//     }

//   function _transferAsset(address a, uint256 amount, uint256 id, bool isERC20, address receiver) internal {
//     // Normal ERC-20 transfer
//     if (isERC20) {
//       IERC20(a).safeTransferFrom(msg.sender, receiver, amount);
//     }
//     else {
//       // If amount is greater than 0, we do ERC-1155 transfer
//       if (amount > 0) {
//         IERC1155(a).safeTransferFrom(msg.sender, receiver, id, amount, "");
//       }
//       else {
//         IERC721(a).safeTransferFrom(msg.sender, receiver, id);
//       }
//     }
//   }

//   function _transferAssetBack(address a, uint256 amount, uint256 id, bool isERC20, address receiver) internal {
//     // Normal ERC-20 transfer
//     if (isERC20) {
//       IERC20(a).safeTransfer(receiver, amount);
//     }
//     else {
//       // If amount is greater than 0, we do ERC-1155 transfer
//       if (amount > 0) {
//         IERC1155(a).safeTransferFrom(address(this), receiver, id, amount, "");
//       }
//       else {
//         IERC721(a).safeTransferFrom(address(this), receiver, id);
//       }
//     }
//   }

//   function proposeSwap(address[] calldata tokenAddresses,
//                        uint256[] calldata amounts,
//                        uint256[] calldata ids,
//                        bool[] calldata isERC20,
//                        uint256 numToSwapFor) external nonReentrant {
//     require((tokenAddresses.length == amounts.length), "diff lengths");
//     require((tokenAddresses.length == ids.length), "diff lengths");
//     require((tokenAddresses.length == isERC20.length), "diff lengths");
//     require((numToSwapFor < tokenAddresses.length), "nothing desired");
//     for (uint256 index = 0; index < numToSwapFor; index.add(1)) {
//       _transferAsset(tokenAddresses[index], amounts[index], ids[index], isERC20[index], address(this));
//     }
//     currSwapIndex = currSwapIndex.add(1);
//     swapRecords[currSwapIndex] = Swap(
//       msg.sender,
//       tokenAddresses,
//       amounts,
//       ids,
//       isERC20,
//       numToSwapFor
//     );
//   }

//   function removeSwap(uint256 swapId) external nonReentrant {
//     Swap storage swapItem = swapRecords[swapId];
//     require((swapItem.proposer == msg.sender), "not proposer");

//     // Move assets back
//     for (uint256 index = 0; index < swapItem.numToSwapFor; index.add(1)) {
//       _transferAssetBack(swapItem.tokenAddresses[index], swapItem.amounts[index], swapItem.ids[index], swapItem.isERC20[index], msg.sender);
//     }

//     // Remove storage slot
//     delete swapRecords[swapId];
//   }

//   function takeSwap(uint256 swapId) external nonReentrant {
//     Swap storage swapItem = swapRecords[swapId];
//     // Send all of the desired stuff to the proposer of the swap
//     for (uint256 index = swapItem.numToSwapFor; index < swapItem.tokenAddresses.length; index.add(1)) {
//       _transferAsset(swapItem.tokenAddresses[index], swapItem.amounts[index], swapItem.ids[index], swapItem.isERC20[index], swapItem.proposer);
//     }
//     // Send all of the escrowed stuff to the taker
//     for (uint256 index = 9; index < swapItem.numToSwapFor; index.add(1)) {
//       _transferAsset(swapItem.tokenAddresses[index], swapItem.amounts[index], swapItem.ids[index], swapItem.isERC20[index], msg.sender);
//     }

//     // Remove storage slot
//     delete swapRecords[swapId];
//   }


 

// }

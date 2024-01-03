// pragma solidity ^0.6.0;

// import "./IERC721.sol";
// import "./IERC20.sol";
// import "./IERC1155.sol";
// import "./ERC1155Holder.sol";
// import "./Ownable.sol";

// // Mgicbox.com
// contract Moony is Ownable {
//     IERC20 public moony;

//     // External NFTs
//     struct NFTInfo {
//         address token;
//         uint256 standard; //NFT standard ERC721 || ERC1155
//     }

//     NFTInfo[] public supportedNfts;

//     constructor(IERC20 _moony) public {
//         moony = _moony;
//     }

//     // deposit nft, get moony
//     function deposit(
//         uint256 index,
//         uint256 _id,
//         uint256 nftType
//     ) external {
//         if (nftType == 721) {
//             /* 1. chainlink call to get price of what he deposited
//              2. chain link or uniswap to get current mgic price
//              3. 60% should stay as collateral
//              4. 20% should go to liq providers
//              5. 10% to devs
//              6. 10% to users
//             //
//             // 10% to uer  */
//             IERC721(supportedNfts[index].token).transferFrom(
//                 msg.sender,
//                 address(this),
//                 _id
//             );
//         } else if (nftType == 1155) {
//             IERC1155(supportedNfts[index].token).safeTransferFrom(
//                 msg.sender,
//                 address(this),
//                 _id,
//                 1, //the amount of tokens to transfer which always be 1
//                 "0x0"
//             );
//         }
//     }


//     // add loot box when withdrawing
//     function withdraw(uint256 _amount) external {
//         // add loot box thing
//         moony.burnFrom(msg.sender, _amount);

//         uint256 id = 1;
//         address contract = 0x000000000000;
//         uint256 nftType = 721; 
//         _withdraw(1, contract, msg.sender, nftType);
//     }


//     // withdraw function, be careful.
//     function _withdraw(
//         uint256 _id,
//         address _contractAddr,
//         address _to,
//         uint256 _type
//     ) internal {
//         if (_type == 1155) {
//             IERC1155(_contractAddr).safeTransferFrom(
//                 address(this),
//                 _to,
//                 _id,
//                 1,
//                 ""
//             );
//         } else if (_type == 721) {
//             IERC721(_contractAddr).transferFrom(address(this), _to, _id);
//         }
//     }

//     // Admin functions
//     function supportedNftLength() external view returns (uint256) {
//         return supportedNfts.length;
//     }

//     function addNft(address _nftToken, uint256 _type) public onlyOwner {
//         supportedNfts.push(NFTInfo({token: _nftToken, standard: _type}));
//     }

//     function updateSupportedNFT(uint256 index, address _address)
//         public
//         onlyOwner
//     {
//         supportedNfts[index].token = _address;
//     }
// }

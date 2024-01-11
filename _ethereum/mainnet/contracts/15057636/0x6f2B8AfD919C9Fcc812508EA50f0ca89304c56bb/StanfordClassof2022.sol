// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

/*
MMMWNNWMMMWNNWMMMWNNWMMMWWNWMMMWWNWWMMWWNWWMMMWNNWMMMWNNWMMMWNNWMMMWNNWMMMWWWNWMMMWWNWWMMWWNWWMMMWNWWMMMWNNWMMMWNNWMMMWNNWMMMWNNWMMMWWNWWMMWWNWWMMMWNN
MMMWWWWMMMWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWMMMWWWWMMMWWWWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMMWWWW
WWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWWMMWWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWWMM
WWWWMWWWWWWMMWWWWWWWWWWWWWMWWWWWWWWWWWWWMWWWWWWMWWWWWWWWWNNNWWWWNNNWWWWNNNNWWWWNNNNWWWNNNNWWWNNWWWMWWWWWWMWWWWWWMMWWWWWMMWWWWWWMWWWWWWWWWWWWWMWWWWWWWW
MMMWNWWMMMWNNWMMMWNNWMMMWWNWWMMWWNWWMMWWNWWMMWWNWWMMNklclllllllllllllllllllllllllllllllllllllllxXWWWWMMMWNWWMMMWNNWMMMWWNWMMMWWNWWMMWWNWWMMWWNWWMMMWNN
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNkc:dkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOx::xXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
NNWMMMWWNWWMMWWNWWMMMWNNWMMMWNNWMMMWNNWMMMWNNWMMXx::d0xc,,,,,,,,,,,,,,,,,;;,,,,,,,,,,,,,,,,,,:x0xc:dKWNWMMMWNNWMMMWWNWWMMMWNNWMMMWNNWMMMWNNWMMMWNNWMMM
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXx::x0x:..................,dd:,..................;d0kc:dKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
MMMWWWWMMMWWNWMMMWWNWMMMWWNWWMMWWNWWMMWWNWWWXd:cx0x;...................'lkxkl,...................;dOkc:oKNWWMMMWNWWMMMWWWWMMMWWNWWMMWWNWWMMWWNWWMMWWNW
WWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWWMWWWWWWWWKd:ck0d;....................;dx:cdkd'....................,oOkc;o0NWWWWWMWWWWWMMWWWWWMMWWWWWWMWWWWWWMWWWWWWMM
WWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWWKo:ckOd;......................;xx;;coxl'.....................,oOkl;l0NWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWWMM
MMMWWWWMMMWWWWMMMWWWWMMMWWWWWMMWWWWWMMM0;:k0o,......................,oxo:,,,ckl........................,lOOc,kWWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMMWWWW
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk,dNo........................;xOd:,,,;lol,........................cKx,xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
NNWMMMWWNWWMMWWNWWMMMWNNWMMMWNNWMMMWNNWk,dNl......................'cdoc;,,,,,;dk:........................:Kx,xWMMMWWNWWMMMWNNWMMMWNNWMMMWNNWMMMWNNWMMM
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk,dNl......................'codl,,,,,,,codc'......................:Kx,xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
MMMWNNWMMMWNNWMMMWNNWMMMWWNWMMMWWNWWMMMk,dNl.....................':cll:,,,,,,,lddl'......................:Kx,xWWNNWMMMWNNWMMMWNNWMMMWWNWWMMWWNWWMMMWNN
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk,dNl....................,dOdlll:,,,,,,:olcc,.....................:Kx,xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWNWk,dNl....................',:ldxd:,,,,,,,;codkl....................:Kx,xWMMMWWWWWMMWWWWWMMMWWWWMMMWWWWMMMWWWWMMM
MMWWWWWMMWWWWWMMMWWWWWMMWWWWWMMWWWWWMMMk,dNl...................':llll:,,,,,,,,;dkxdl;....................:Kx,xWWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWW
MMWWWWWWMWWWWWWMWWWWWWMMWWWWWMMWWWWWMWWk,dNl.................;looc;,,,,,,,,,,,,;cllll;'................'.cKx,xWWWWWWMWWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWW
WNWWMMWWNWWMMWWNWWMMWWNWWMMMWNWWMMMWNNWO,dNl...............,oxo:::codc,,,,,,,,,,,,,;coxOkxkkkkkkkkkkkkkkkOXd,xWMMMWWNWWMMWWNWWMMMWWWWMMMWNWWMMMWWNWMMM
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk,dNl...............;olcccclxkc,,,,,,,,,colcc::cxOolllllllllllllllllc;kWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
MMMWNNWMMMWNNWMMMWNNWMMMWNNWMMMWWNWWMMMk,dNl....................,coo:,,,,,,,,,,ckxdkkxxxxk0XXXXXXXXXXXXXXXXXXWMWNNWMMMWNNWMMMWNNWMMMWWNWWMMWWNWWMMMWNN
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWO,dNl.................,clol:,,,,,,,,,,,,,:oxkOO0OOKXKKXXXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
WNWWMMWWNWWMMWWNWWMMWWNWWMMMWNWWMMMWNNWO,dNl...............'cdl;,,,,,,,,,,,,,,,,,,:loddolllllllccdKWWWNWMMMWWNWMMMWWNWWMMWWNWWMMMWNWWMMMWNNWMMMWWNWMMM
WMWWWWWWMWWWWWWMWWWWWWMWWWWWWMMWWWWWWWWk,dNl...............cx:,,,,,:c;,,,,,,,,,,,,,,,;lkKOkkkkkOkc:dKWWWWWWWWMWWWWWWMWWWWWWMWWWWWWWMWWWWWMMWWWWWMMWWWW
MMWWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMMMk,dNl..............'odclllclkOc,,,,,,,,,;clc:,,,:xl.....;dOkc:dKWWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWW
WWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWO,dNl..............'oxl:;llloc,,,,,,,,,,ckxccllllxd'......,dOkc:dKWMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWMMMWWWWMMM
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWO,dNl...............''.ckxolloo;,,,,,,,,,colcc;;cl:.........,dOkc:dKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
MMMWNNWMMMWNNWMMMWNNWMMMWNNWMMMWWNWWMMMk,oNd'.................;ccccokd;,,,,,,,,:c;;codl,.............,dOkc:dKWMWNNWMMMWNNWMMMWNNWMMMWWNWWMMWWNWWMMMWNN
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWKl;d0kc'.................,clol;,,,,,,,,,oOxlccld:...............,oOk:;OWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
NNWMMMWWNWWMMWWNWWMMMWNNWMMMWNNWMMMWNNWMNOc:d0kc'............;llll:,,,,,,,,,,,,;cooc;'...................cXx,xWMMMWWNWWMMMWNNWMMMWNNWMMMWNNWMMMWNNWMMM
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNOc:d0kc'.........ckxl:::;,,,,,,,,,,,,,,:llll;.................:Kx,xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
MMMWWWWMMMWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMNOc:dOkc'.......coccclxl,,,,,,,,,,,,,,,,,;ldc'...............:Kx,xWWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMMWWWW
WWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWWMMWWWWNOc:oOkc,,,,,,,',;cloc,,,,,,,,,,,,,cxolcclxl...............:Kx,xWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWWMMWWWWWMM
WWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWWMWWWWWWWNkc:okkxxxxk0Odol:,,,,,,,,,,,,,,,:dxxdlcoc'..............:Kx,xWWMMWWWWWMMWWWWWMMWWWWWWMWWWWWWMWWWWWWMM
MMMWWWWMMMWWWWMMMWWWWMMMWWNWWMMWWNWWMMWWNWWMMWWNWWNOlclllccdkl:clol:,,,,,,,,,,,,,,,:llll:'...............:Kx,xWWNWWMMMWWWWMMMWWNWWMMWWNWWMMWWNWWMMWWNW
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNNXOkxlllldxc,,,,,,,,,,,,,:lolc:cxo'..............:Kx,xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
NNWMMMWWNWWMMWWNWWMMMWNNWMMMWNNWMMMWNNWNXKKKKKKKKKKKKKKKKK0kxoclll;,,,,,,,,,,,,,,:xxllccll,..............:Kx,xWMMMWWNWWMMMWNNWMMMWNNWMMMWNNWMMMWNNWMMM
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWO::llllllllllllllllloOk:,,,,,,,,,,,,,,,,,,,;llcclc'...............:Kx,xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
MMMWNNWMMMWNNWMMMWNNWMMMWWNWMMMWWNWWMMMk,oX0kkkkkkkkkkkkkxk0XXo,,,,,,,,,,,,,,,,,,,,,,,;ox;...............:Kx,xWWNNWMMMWNNWMMMWWNWWMMWWNWWMMWWNWWMMMWNN
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk,dNl.............;lol:,,,,,,,:oc,,,,,,,,,,,,,,;xd,...............:Kx,xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWk,dNl............:xl,,,;:ccclooxd;,,,,,,,,,,,,,,:lol;.............:Kx,xWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWMMMWWWWMMM
MMWWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMMMk,dNl...........,do,:lllcccc:,.ld;,,,,col:;;;;,,,,,lx:............:Kx,xWWWWWMMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWW
WWWWWWWWWWWWWWWWWWWWWWMWWWWWWWWWWWWWWWWk,dNl...........;xdol:,........ld;,,,,dxcccccclllc;,ld,...........:Kx,xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
NNWMMMWWNWWMMWWNWWMMMWNWWMMMWNNWMMMWNNWO,dNl............;c,...........ld;,,,,do.......,:loloxc...........:Kx,xWMMMWWNWWMMWWNWWMMMWNWWMMMWNNWMMMWNNWMMM
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWk,dNl..........................ld;,,,,do..........':cc,...........:Kx,xWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
MMMWNNWMMMWNNWMMMWNNWMMMWNNWMMMWWNWWMMMk,dNo..........................ld;,,,,do..........................cKx,xWWNNWMMMWNNWMMMWNNWMMMWWNWWMMWWNWWMMMWNN
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW0;:O0o,.......................'od,,,,,do........................,lOOc,kWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
WWWWMMWWNWWMMWWNWWMMWWNWWMMMWWWWMMMWWNWWKo:ckOd;.....................:xc,,,,,oo'.....................,lOOl;lONWWMMWWNWWMMWWNWWMMMWWWWMMMWWWWMMMWWWWMMM
MMWWWWWMMWWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWNKd:ck0d;.................:ooc,,,,,,cxc...................,oOkl;l0NWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWW
MMWWWWWMMWWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWWKd:cx0x;.............,odc,,,,,,,,,coo:'..............,oOkc;o0WWWMMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWW
WWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWMMMWWWWXx::x0x:..........:dl;,,,,,,,,,,,,cool,..........;dOkc:oKWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWMMMWWWWMMM
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXx::x0x:,',',;cddl;;;;;;;;;;;;;;;;:odoc;,'''';d0kc:dKWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
MMMWNNWMMMWNNWMMMWNNWMMMWNNWMMMWWNWWMMWWNWWMMMWNNWXkc:dOkxxxxO00kkkkkkkkkkkkkkkkkkkkk00Okxxxxkxc:dKWWMMMWNNWMMMWNNWMMMWNNWMMMWNNWMMMWWNWWMMWWNWWMMMWNN
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXklcllllllllllllllllllllllllllllllllllllllcxXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
NNWMMMWWNWWMMWWNWWMMMWNNWMMMWNNWMMMWNNWMMMWNNWMMMWNNWWWWNNNNNWWNNNNNWWNNNNNWWWNNNNNWWWNNNNNWWNNWWMMMWNNWMMMWWNWWMMWWNWWMMMWNWWMMMWNNWMMMWNNWMMMWNNWMMM
WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
MMMWWWWMMMWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWMMMWWWWMMMWWWWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWMMMWWWWMMMWWWWMMMWWWWWMMWWWWWMMWWWWWMMWWWW
WWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWWMWWWWWWMWWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMMWWWWWMMWWWWWWMWWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWMMWWWWWWMWWWWWWMWWWWWWMM
*/

/*
 * Stanford Class of 2022 NFT based on the Stanford CS 251 NFT | Autumn 2021 Collection
 *
 * Features: Enumerable, Ownable, Non-Transferable, Mintable
 *
 * - Enumerable: totalSupply() can be queried on-chain for convenience.
 * - Owner: Only owner can generate valid mint signatures.
 * - Non-Transferable: Only Class of 2022 students can own a token.
 * - Mintable: Students can mint their own NFT if they have a valid signature.
 *
 */

/// @custom:security-contact stanfordnftproject@gmail.com
contract StanfordClassof2022 is ERC721, ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  struct AddressData {
    bool onAllowList;
    bool hasMinted;
  }

  mapping(address => AddressData) private _addresses;

  constructor() ERC721("Stanford Class of 2022 Token", "Class of 2022") {}

  function _baseURI() internal pure override returns (string memory) {
    return "ipfs://QmSLq8NNMD3Gtba4qV9GqhD27gwSPkYgbMpd7w5kSynRKY";
  }

  // Override required by Solidity.
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // -------- CUSTOM LOGIC ---------------------------

  function addAddressesToAllowlist(address[] calldata aAddresses) external onlyOwner {
    // only the owner can call setAllowList()!
    for (uint i = 0; i < aAddresses.length; i++) {
        AddressData memory toAdd;
        toAdd.hasMinted = false;
        toAdd.onAllowList = true;
        _addresses[aAddresses[i]] = toAdd;
    }
  }

  function isAddressOnAllowList(address add) public view returns (bool) {
    return _addresses[add].onAllowList;
  }

  function mint(address[] calldata aAddresses) external onlyOwner {
    for (uint i = 0; i < aAddresses.length; i++) {
      require(_addresses[aAddresses[i]].onAllowList, "Address must be on the allow list");
      require(!_addresses[aAddresses[i]].hasMinted, "Address can only mint one token");
      _addresses[aAddresses[i]].hasMinted = true;
      _safeMint(aAddresses[i], _tokenIds.current());
      _tokenIds.increment();
    }
  }

  /*
  This mint function is for the system when the users mint their own NFTs

  function mint() public {
    address minter = _msgSender();
    // this might have a bug because contracts did mint
    require(tx.origin == minter, "contracts are not allowed to mint");

    // ensure here the sender does not already own a token
    // numberMinted = uint256(_addressData[owner].numberMinted);
    // LEGACY: require(!_exists(nonce), "Token already minted");
    // LEGACY: require(verifySignature(nonce, signature, owner()), "Invalid signature");

    require(_addresses[minter].onAllowList, "Address must be on the allow list");
    require(!_addresses[minter].hasMinted, "Address can only mint one token");
    _addresses[minter].hasMinted = true;

    
    _safeMint(msg.sender, _tokenIds.current());

    _tokenIds.increment();
  }
  */

  // See https://solidity-by-example.org/signature/
  function verifySignature(
    uint256 nonce,
    bytes memory signature,
    address minter
  ) public pure returns (bool) {
    bytes32 message = getMessageHash(nonce);
    (uint8 v, bytes32 r, bytes32 s) = getVRSFromSignature(signature);
    return ecrecover(message, v, r, s) == minter;
  }

  /**
   * Signature is produced by signing a keccak256 hash with the following format:
   * "\x19Ethereum Signed Message\n" + len(msg) + msg
   * See EIP-191.
   */
  function getMessageHash(uint256 nonce) public pure returns (bytes32) {
    bytes32 message = keccak256(abi.encodePacked(nonce));
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
  }

  function getVRSFromSignature(bytes memory signature)
    public
    pure
    returns (
      uint8 v,
      bytes32 r,
      bytes32 s
    )
  {
    require(signature.length == 65, "Invalid signature length");
    // solhint-disable-next-line no-inline-assembly
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }
  }

  /**
   * Override Open Zeppelin's tokenURI() since it concatenates tokenId to
   * baseURI by default, but in our case each token has the same metadata.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return _baseURI();
  }

  // Non-transferability
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    require(from == address(0), "Token is not transferable");
    super._beforeTokenTransfer(from, to, tokenId);
  }
}

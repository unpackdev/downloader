// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721Pausable.sol";
import "./Ownable.sol";

contract Gachadass is ERC721Pausable, Ownable {

  event Item_Changed(
      uint256 index
  );

  event Assortment_Changed(
      uint256 index
  );

  event Gacha_Changed(
      uint256 index
  );

  event New_Token(
      uint256 id,
      uint32 image,
      uint144 value
  );

  event Config_Changed(
      uint16 gacha_data_length,
      uint16 items_length,
      uint16 assortments_length,
      uint72 free_gift
  );

  struct Gacha_Data {
      uint8[] rates;
      uint32[] common_items;
      uint32[] uncommon_items;
      uint32[] rare_items;
      uint72 price;
      bool released;
  }

  struct Token_Data {
      uint32 image;
      uint144 value;
  }

  struct Item {
      uint32 image;
      uint144 value;
      uint72 price;
      uint8 gacha_id;
  }

  struct Assortment_Data {
      uint16 start;
      uint8 length;
      uint72 price;
      bytes20 hash;
  }

  struct Config {
      uint16 gacha_data_length;
      uint16 items_length;
      uint16 assortments_length;
      uint72 free_gift;
  }

  struct Token {
      uint256 id;
      Token_Data data;
      address owner;
  }

  struct Assortment {
      Assortment_Data assortment;
      Item[] items;
  }

  mapping (uint256 => Token_Data) private token_data;
  mapping (uint256 => Gacha_Data) private gacha_data;
  mapping (uint256 => Item) private items;
  mapping (uint256 => Assortment_Data) private assortments;
  mapping (address => uint256) private coins;

  Config private config;
  address private minter;
  uint256 private token_id;
  string private base_uri;

  constructor(string memory name, string memory symbol, string memory uri) ERC721(name, symbol) {
      base_uri = uri;
  }

  function mint(uint256 id, address to, uint32 image, uint144 v) private {
      require(image > 0);
      _mint(to, id);
      token_data[id]=Token_Data(
          image,
          v
      );
      emit New_Token(id, image, v);
  }

  function mint_by_owner(address to, uint32 image, uint144 v) external {
      require(msg.sender == owner() || msg.sender == minter);
      mint(token_id, to, image, v);
      token_id += 1;
  }

  function set_minter(address minter_) external onlyOwner {
      minter = minter_;
  }

  function sendEtherToOwner(uint256 amount) external onlyOwner {
      require(address(this).balance >= amount);
      payable(owner()).transfer(amount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return base_uri;
  }

  function set_base_uri(string calldata uri) external {
      require(msg.sender == owner() || msg.sender == minter);
      base_uri = uri;
  }

  function add_coins(address to, uint256 amount) external {
      require(msg.sender == owner() || msg.sender == minter);
      coins[to] += amount;
  }

  function gacha(uint256 index, uint256 random) public view returns(uint32, uint144) {
      if (index > 127) {
          index -= 128;
      }
      uint32 image;
      uint144 r;
      assembly {
          let freemem_pointer := mload(0x40)
          mstore(freemem_pointer, random)
          mstore(add(freemem_pointer, 0x20), timestamp())
          mstore(add(freemem_pointer, 0x40), difficulty())
          r := keccak256(freemem_pointer, 0x60)

          mstore(freemem_pointer, index) // mapping key
          mstore(add(freemem_pointer, 0x20), gacha_data.slot) // mapping slot
          mstore(freemem_pointer, keccak256(freemem_pointer, 0x40)) // gacha_data position
          mstore(add(freemem_pointer, 0x20), add(mload(freemem_pointer), 0)) // rates position
          mstore(add(freemem_pointer, 0x40), sload(keccak256(add(freemem_pointer, 0x20), 0x20))) // rates data

          switch lt(div(mul(byte(30, r), 99), 255), byte(31, mload(add(freemem_pointer, 0x40))))
          case 1 {
              mstore(add(freemem_pointer, 0x60), add(mload(freemem_pointer), 3)) //　rare position
          }
          default {
              switch lt(div(mul(byte(30, r), 99), 255), byte(30, mload(add(freemem_pointer, 0x40))))
              case 1 {
                  mstore(add(freemem_pointer, 0x60), add(mload(freemem_pointer), 2)) //　uncommon position
              }
              default {
                  mstore(add(freemem_pointer, 0x60), add(mload(freemem_pointer), 1)) //　common position
              }
          }
          mstore(add(freemem_pointer, 0x80), sload(mload(add(freemem_pointer, 0x60)))) // length
          mstore(add(freemem_pointer, 0xA0),
          div(mul(byte(29, r), sub(mload(add(freemem_pointer, 0x80)), 1)), 255)) // item index
          mstore(add(freemem_pointer, 0xC0), sload(add(keccak256(add(freemem_pointer, 0x60), 0x20), div(mload(add(freemem_pointer, 0xA0)), 8))))
          image :=  and(mload(sub(add(freemem_pointer, 0xC0), mul(0x4, mod(mload(add(freemem_pointer, 0xA0)), 8)))), 0xffffffff)
      }
      return (image, r);
  }

  function shop(uint256 index, uint32 img, uint256 v) payable whenNotPaused external {
      require(config.items_length > index);

      uint32 image = items[index].image;
      uint144 value = items[index].value;
      uint72 price = items[index].price;
      bool bonus;

      if (items[index].gacha_id > 127) {
          bonus = true;
      }

      require(price > 0);
      require(value == v);
      require(image == img);

      if (bonus) {
          require(coins[msg.sender] >= price);
      }
      else {
          require(price == msg.value);
      }

      mint(token_id, msg.sender, image, value);
      token_id += 1;

      if (bonus) {
          coins[msg.sender] -= price;
      }
      else if (config.free_gift > 0) {
          coins[msg.sender] += msg.value / config.free_gift;
      }

      update_item(index);
  }

  function shop(uint256 index, bytes32 hash_) payable whenNotPaused external {
      require(config.assortments_length > index);

      uint16 start = assortments[index].start;
      uint8 length = assortments[index].length;
      uint72 price = assortments[index].price;
      bytes20 hash = assortments[index].hash;
      bool del;
      bool bonus;

      if (items[start].gacha_id > 127) {
          bonus = true;
      }
      require(price > 0);
      require(length > 0);
      require(hash == hash_);

      if (bonus) {
          require(coins[msg.sender] >= price);
      }
      else {
          require(price == msg.value);
      }

      for (uint256 i = 0; i < length; i++) {
          mint(token_id + i, msg.sender, items[i + start].image, items[i + start].value);
          if (update_item(i + start) && !del) {
              del = true;
          }
      }
      token_id += length;
      if (bonus) {
          coins[msg.sender] -= price;
      }
      else if (config.free_gift > 0) {
          coins[msg.sender] += msg.value / config.free_gift;
      }

      if (del) {
          delete assortments[index];
      }
      else {
          assortments[index].hash = assortment_hash(start, length);
      }

      emit Assortment_Changed(index);
  }

  function set_item(uint256 index, uint32 image, uint144 value, uint72 price, uint8 gacha_id) external onlyOwner {
      items[index] = Item(image, value, price, gacha_id);
      emit Item_Changed(index);
  }

  function set_items(uint256 index, Item[] memory items_) external onlyOwner {
      for (uint256 i = 0; i < items_.length; i++) {
          items[index + i] = items_[i];
          emit Item_Changed(index + i);
      }
  }

  function update_item(uint256 index) private returns(bool) {
      uint32 image = items[index].image;
      uint144 value = items[index].value;
      uint72 price = items[index].price;
      uint8 gacha_id = items[index].gacha_id;
      bool del;
      if (gacha_id == 127 || gacha_id == 255) {
          bytes32 hash = keccak256(abi.encodePacked(
                  value,
                  block.timestamp,
                  block.difficulty
          ));
          items[index].value = uint144(uint256(hash));
      }
      else if ((gacha_id > 127 && gacha_data[gacha_id - 128].released == true) || (gacha_id < 128 && gacha_data[gacha_id].released == true)) {
          (image, value) = gacha(gacha_id, value);
          items[index] = Item(image, value, price, gacha_id);
      }
      else {
          delete items[index];
          del = true;
      }
      if (index < config.items_length) {
          emit Item_Changed(index);
      }
      return del;
  }

  function assortment_hash(uint256 start, uint256 length) private view returns(bytes20) {
      bytes32 hash;
      uint256 assortment_length = length + start;
      for (uint256 i = start; i < assortment_length; i++) {
          hash = keccak256(abi.encodePacked(
              hash,
              items[i].value
          ));
      }
      return bytes20(hash);
  }

  function set_assortment(
        uint256 index,
        uint16 start,
        uint8 length,
        uint72 price,
        Item[] calldata items_
  )
        external onlyOwner
  {
      for (uint256 i = 0; i < items_.length; i++) {
          items[start + i] = items_[i];
      }
      assortments[index] = Assortment_Data(
          start,
          length,
          price,
          assortment_hash(start, length)
      );
      emit Assortment_Changed(index);
  }

  function set_config(
      uint16 gacha_data_length,
      uint16 items_length,
      uint16 assortments_length,
      uint72 free_gift
  )
      external onlyOwner
  {
      config = Config(
          gacha_data_length,
          items_length,
          assortments_length,
          free_gift
      );
      emit Config_Changed(
          gacha_data_length,
          items_length,
          assortments_length,
          free_gift
      );
  }

  function bonus_gacha(uint256 index, uint256 quantity) whenNotPaused external {
      require (gacha_data[index].released == true);
      require (config.gacha_data_length > index);
      require (gacha_data[index].price > 0);
      require (quantity > 0);
      require (coins[msg.sender] >= gacha_data[index].price * quantity);
      uint32 image;
      uint144 r;
      uint256 id = token_id;

      for (uint256 i = 0; i < quantity; i++) {
          unchecked {
              (image, r) = gacha(
                  index,
                  token_data[id + i - 1].value + token_data[id + i - 2].value
              );
          }
          mint(id + i, msg.sender, image, r);
      }

      coins[msg.sender] -= gacha_data[index].price * quantity;
      token_id += quantity;
  }

  function set_gacha_data(
      uint256 index,
      Gacha_Data calldata gacha_data_
  )
      external
      onlyOwner
  {
      gacha_data[index] = gacha_data_;
      emit Gacha_Changed(index);
  }

  function add_gacha_item(
      uint256 index,
      uint256 rarity,
      uint32 image,
      uint256 item_index
  )
      external
      onlyOwner
  {
      if (rarity == 0) {
          if (item_index < gacha_data[index].rare_items.length) {
              gacha_data[index].rare_items[item_index] = image;
          }
          else {
              gacha_data[index].rare_items.push(image);
          }
      }
      else if (rarity == 1) {
          if (item_index < gacha_data[index].uncommon_items.length) {
              gacha_data[index].uncommon_items[item_index] = image;
          }
          else {
              gacha_data[index].uncommon_items.push(image);
          }
      }
      else {
          if (item_index < gacha_data[index].common_items.length) {
              gacha_data[index].common_items[item_index] = image;
          }
          else {
              gacha_data[index].common_items.push(image);
          }
      }
      emit Gacha_Changed(index);
  }

  function release(uint256 index) external onlyOwner {
      gacha_data[index].released = true;
      emit Gacha_Changed(index);
  }

  function unrelease(uint256 index) external onlyOwner {
      gacha_data[index].released = false;
      emit Gacha_Changed(index);
  }

  function pause() external onlyOwner {
      _pause();
  }

  function unpause() external onlyOwner {
      _unpause();
  }

  receive() external payable {}

  fallback() external payable {}

  function get_minter() external view returns(address) {
      return minter;
  }

  function get_data_all()
      external
      view
      returns(
          Config memory,
          Item[] memory,
          Assortment[] memory,
          Gacha_Data[] memory
      )
  {
      return (
          config,
          get_items(),
          get_assortments(),
          get_gacha_data_all()
      );
  }

  function get_item(uint256 index) external view returns(Item memory) {
      return items[index];
  }

  function get_items() public view returns(Item[] memory) {
      uint256 length = config.items_length;
      Item[] memory items_ = new Item[](length);
      for (uint256 i = 0; i < length; i++) {
          items_[i] = items[i];
      }
      return (items_);
  }

  function get_assortment(uint256 index) public view returns(Assortment memory) {
    uint16 start = assortments[index].start;
    uint8 length = assortments[index].length;
    Item[] memory items_ = new Item[](length);
    for (uint256 i = 0; i < length; i++) {
        items_[i] = items[i + start];
    }
      return Assortment(assortments[index], items_);
  }

  function get_assortments() public view returns(Assortment[] memory) {
      uint256 length = config.assortments_length;
      Assortment[] memory assortments_ = new Assortment[](length);
      for (uint256 i = 0; i < length; i++) {
          assortments_[i] = get_assortment(i);
      }
      return (assortments_);
  }

  function get_coins(address user) external view returns(uint256) {
      return coins[user];
  }

  function get_tokens(uint256 start, uint256 end, address user, bool filter) external view returns(Token[] memory) {
      uint256 length = token_id;
      uint256 balance_count;
      if (end > length) {
          end = length;
      }
      if (filter == true) {
          for (uint256 i = start; i < end; i++) {
              if (ownerOf(i) == user) {
                  balance_count += 1;
              }
          }
      }
      else {
          balance_count = length;
      }

      Token[] memory tokens = new Token[](balance_count);
      balance_count = 0;
      for (uint256 i = start; i < end; i++) {
          if (filter == false || (filter == true && ownerOf(i) == user)) {
              tokens[balance_count] = Token(
                i,
                token_data[i],
                ownerOf(i)
              );
              balance_count += 1;
          }
      }
      return (tokens);
  }

  function get_config() external view returns(Config memory) {
      return config;
  }

  function get_gacha_data(uint256 index) external view returns(Gacha_Data memory) {
      return gacha_data[index];
  }

  function get_gacha_data_all() public view returns(Gacha_Data[] memory) {
      uint256 length = config.gacha_data_length;
      Gacha_Data[] memory gacha_data_ = new Gacha_Data[](length);
      for (uint256 i = 0; i < length; i++) {
          gacha_data_[i] = gacha_data[i];
      }
      return (gacha_data_);
  }

  function get_token_data(uint256 id) external view returns(Token_Data memory) {
      return token_data[id];
  }

}

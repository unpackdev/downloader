// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library MapPurchase {
  struct Purchase {
    uint8 divisor;
    uint8 personaAmount;
    uint256 tokenAmount;
    uint256 bonusAmount;
    address account;
    uint256 purchasedAmount;
  }

  struct Record {
    Purchase[] values;
    mapping(address => uint256) indexes; // value to index
  }

  function addValue(
    Record storage _record,
    address _purchaser,
    uint256 _purchased,
    uint16 _unit,
    uint8 _decimals,
    function(uint256, uint16) internal pure returns (uint16, uint8) getRate
  ) internal {
    if (containsValue(_record, _purchaser)) return; // exist
    (uint256 tokenAmount, uint256 bonusAmount, uint8 personaAmount) = Utilities.computeReward(_purchased, _unit, _decimals, getRate);
    Purchase memory _value = Purchase({ divisor: 12, personaAmount: personaAmount, tokenAmount: tokenAmount, bonusAmount: bonusAmount, account: _purchaser, purchasedAmount: _purchased });
    _record.values.push(_value);
    _record.indexes[_purchaser] = _record.values.length;
  }

  function removeValue(Record storage _record, Purchase memory _value) internal {
    uint256 valueIndex = _record.indexes[_value.account];
    if (valueIndex == 0) return;
    uint256 toDeleteIndex = valueIndex - 1;
    uint256 lastIndex = _record.values.length - 1;
    if (lastIndex != toDeleteIndex) {
      Purchase memory lastvalue = _record.values[lastIndex];
      _record.values[toDeleteIndex] = lastvalue;
      _record.indexes[lastvalue.account] = valueIndex;
    }
    _record.values.pop();
    _record.indexes[_value.account] = 0;
  }

  function containsValue(Record storage _record, address _account) internal view returns (bool) {
    return _record.indexes[_account] != 0;
  }

  function getValue(Record storage _record, address _account) internal view returns (Purchase memory) {
    if (!containsValue(_record, _account)) {
      return Purchase({ divisor: 12, personaAmount: 0, tokenAmount: 0, bonusAmount: 0, account: _account, purchasedAmount: 0 });
    }
    uint256 valueIndex = _record.indexes[_account];
    return _record.values[valueIndex - 1];
  }
}

library Utilities {
  function computeReward(
    uint256 purchased,
    uint16 unit,
    uint8 decimals,
    function(uint256, uint16) internal pure returns (uint16, uint8) getRate
  )
    internal
    pure
    returns (
      uint256,
      uint256,
      uint8
    )
  {
    uint256 tokenAmount = uint256((purchased * unit) / 1 ether) * (10 ** decimals);

    (uint16 rate, uint8 persona) = getRate(purchased, unit);
    uint256 bonusAmount = uint256((purchased * rate) / 1 ether) * (10 ** decimals);

    return (tokenAmount, bonusAmount, persona);
  }

  function getPrivateBonus(uint256 purchased, uint16 unit) internal pure returns (uint16, uint8) {
    if (purchased >= 2 ether && purchased < 4 ether) {
      return ((unit / 100) * 10, 10);
    }

    if (purchased >= 4 ether && purchased < 6 ether) {
      return ((unit / 100) * 15, 15);
    }

    if (purchased >= 6 ether && purchased < 9 ether) {
      return ((unit / 100) * 25, 25);
    }

    if (purchased >= 9 ether && purchased < 15 ether) {
      return ((unit / 100) * 30, 35);
    }

    if (purchased >= 15 ether && purchased < 19 ether) {
      return ((unit / 100) * 35, 45);
    }

    if (purchased >= 19 ether) {
      return ((unit / 100) * 50, 88);
    }

    return (0, 0);
  }

  function getPublicBonus(uint256 purchased, uint16 unit) internal pure returns (uint16, uint8) {
    if (purchased >= 0.5 ether && purchased < 1 ether) {
      return ((unit / 100) * 2, 2);
    }

    if (purchased >= 1 ether && purchased < 3 ether) {
      return ((unit / 100) * 5, 5);
    }

    if (purchased >= 3 ether && purchased < 6 ether) {
      return ((unit / 100) * 10, 10);
    }

    if (purchased >= 6 ether) {
      return ((unit / 100) * 15, 15);
    }

    return (0, 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISeaToken {
  function transferTaxRate() external view returns (uint16);
}

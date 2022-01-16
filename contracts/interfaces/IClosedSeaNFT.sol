// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IClosedSeaNFT {
  function mint(address _to, uint256 _tokenId, uint256 _price) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import '../utils/MinterRole.sol';

contract ClosedSeaNFT is ERC721('Closed Sea NFT', 'CSNFT'), MinterRole, Ownable {

  using SafeERC20 for IERC20;

  uint256 public tokenCountMinted = 0;
  mapping (uint256 => string) public tokenURIList;  // token id => token URI
  address payable public feeAddress;
  IERC20 public sea;
  uint256 public mintPriceInETH;
  uint256 public seaAmountForExemptFee;

  constructor(address payable _feeAddress, uint _mintPriceInETH, uint _seaAmountForExemptFee, address _sea) public {
    feeAddress = _feeAddress;
    mintPriceInETH = _mintPriceInETH;
    seaAmountForExemptFee = _seaAmountForExemptFee;
    sea = IERC20(_sea);
  }

  function setFeeAddress(address payable _feeAddress) external onlyOwner {
    feeAddress = _feeAddress;
  }

  function setMintPriceInETH(uint _mintPriceInETH) external onlyOwner {
    mintPriceInETH = _mintPriceInETH;
  }

  function setSeaAmountForExemptFee(uint _seaAmountForExemptFee) external onlyOwner {
    seaAmountForExemptFee = _seaAmountForExemptFee;
  }

  function setSeaAddress(address _sea) external onlyOwner {
    sea = IERC20(_sea);
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked('https://gateway.pinata.cloud/ipfs/', tokenURIList[tokenId]));
  }

  function mintWithETH(string memory _uri) external payable {
    uint seaBal = sea.balanceOf(msg.sender);
    if (seaBal < seaAmountForExemptFee) {
      require(msg.value >= mintPriceInETH, 'ClosedSeaNFT: mint price insufficient');
      feeAddress.transfer(mintPriceInETH);
    }
    _mint(msg.sender, tokenCountMinted);
    tokenURIList[tokenCountMinted] = _uri;
    tokenCountMinted++;

    // refund dust
    uint dust = seaBal >= seaAmountForExemptFee ? msg.value : msg.value - mintPriceInETH;
    if (dust > 0) {
      payable(msg.sender).transfer(dust);
    }
  }
}

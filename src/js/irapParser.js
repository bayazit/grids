const IRAP_NULL_VALUE = 9999900

// На вход подается source: string - содержимое irap файла.
function parseIrap(source) {
  let index = 0

  function isDigit(c) {
    return typeof c === 'string' && c.length === 1 && ((c >= '0' && c <= '9') || (c === '-') || (c === '.'));
  }
  function getNextNumberAsString() {
    let value = undefined
    while (index < source.length && !isDigit(source.at(index))) index++
    const indexStart = index
    while (index < source.length && isDigit(source.at(index))) index++
    if (indexStart < index) {
      value = source.substring(indexStart, index)
    }
    return value
  }

  function getNextInt() {
    const s = getNextNumberAsString()
    return parseInt(s)
  }

  function getNextFloat() {
    const s = getNextNumberAsString()
    return parseFloat(s)
  }

  getNextInt()
  const mapHeight = getNextInt()
  for (let i = 0; i < 6; i++) {
    getNextFloat()
  }
  const mapWidth = getNextInt()
  for (let i = 0; i < 10; i++) {
    getNextFloat()
  }

  let arr = []
  let mapMinValue = Number.MAX_VALUE
  let mapMaxValue = -Number.MAX_VALUE
  while (true) {
    const s = getNextNumberAsString()
    if (s === undefined) {
      break
    }
    const value = parseFloat(s)
    if (value !== IRAP_NULL_VALUE) {
      if (value > mapMaxValue) {
        mapMaxValue = value
      }
      if (value < mapMinValue) {
        mapMinValue = value
      }
    }
    arr.push(value)
  }

  // транспонируем
  // let arr2 = []
  // if (mapWidth !== undefined && mapHeight !== undefined) {
  //   for (let h = 0; h < mapHeight; h++ ) {
  //     for (let w = 0; w < mapWidth; w++ ) {
  //       arr2.push(arr[w * mapHeight + h])
  //     }
  //   }
  // }

  const mapImage = new Float32Array(arr)
  return {mapWidth, mapHeight, mapMinValue, mapMaxValue, mapImage}
}
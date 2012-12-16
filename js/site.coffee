# -----------------------------------------------------------------------------
# DEBUGGING STUFF
# -----------------------------------------------------------------------------

debug_mode = true

demo_letters = [
  "b", "s", "n", "n", "x",
  "r", "d", "e", "o", "c",
  "o", "c", "e", "z", "s",
  "o", "o", "l", "m", "i",
  "r", "n", "g", "k", "c",
]

l = (log) -> console.log log if debug_mode
delay = (ms, func) -> setTimeout func, ms
clone_array = (arr) -> arr.slice 0

log_belongings = ->
  l "My tiles (#{ cheater_tiles.length })"
  l cheater_tiles
  l "Opponent tiles (#{ opponent_tiles.length })"
  l opponent_tiles

# -----------------------------------------------------------------------------
# GLOBAL VARIABLES
# -----------------------------------------------------------------------------

# Words hold all the dictionary - everything loaded from all_words.txt
words = []

# letters hold 25 letters on the board
letters = []

# possible_words is words filtered by letters
# - only words that are possible are kept
possible_words = []

# holds words that are already used
used_words = []
cheater_played_words = []
opponent_played_words = []
cheater_started = true

# possible answers hold every possible word and letter arrangement for
# that turn
possible_answers = []
suggested_answer = []

# holds ids of tiles in players possession
cheater_tiles = []
opponent_tiles = []


# -----------------------------------------------------------------------------
# READY EVENT
# -----------------------------------------------------------------------------

$ ->

  # fills `words` with all the words from all_words.txt
  $.ajax
    url: 'all_words.txt'
    success: (data) ->
      words = ( word.replace(/^\s+|\s+$/g, '').toLowerCase()
        for word in data.split "\n" )

  # create input fields
  $('.input').each ->
    id = $(@).attr('id').substr 6
    $(@).attr('data-id', id).html "<input type='text' id='field_#{ id }' />"
    $('input', @).val demo_letters[parseInt(id)] if debug_mode

  $('.input input').on 'keypress', ->
    id = $(@).parent().data 'id'
    $("#field_#{ id + 1 }").focus() if id < 24

    # quick validation to enable Analyze button
    if (true for i in [0..24] when $("#field_#{ i }").val().length > 0).length == 24
      $('#analyze_action').attr 'disabled', false

  $('#field_0').focus()

  $('ul.players').addClass 'clickable'
  $('ul.players li').click ->
    if $('ul.players').hasClass 'clickable'
      $('ul.players li').removeClass 'active'
      $(@).addClass 'active'
      cheater_started = $(@).attr('id').indexOf('opponent') == -1


  $('#analyze_action').on 'click', ->
    $('ul.players').removeClass('clickable').addClass 'counting'
    update_counts()
    $(@).attr 'disabled', true
    $('.input input').each -> letters.push $(@).val().toLowerCase()
    $('.input').each -> $(@).addClass('static').html $('input', @).val().toLowerCase()

    delay 100, ->
      possible_words = (word for word in words when is_possible word)
      $('#analyze_action').hide()
      $('.grid').addClass 'top-shifted'
      if cheater_started then do_cheater_turn() else do_opponent_turn()

  $('#clear_action').on 'click', -> clear_letters()
  $('#submit_action').on 'click', ->
    letter_ids = ( parseInt($(".input[data-letter-id='#{ i }']").attr('data-id')) for i in [1..$('.called-letter').length] )
    played_word = ( letters[id] for id in letter_ids ).join('')
    if block_used_word played_word
      opponent_played_words.push played_word
      give_tiles letter_ids, cheater_tiles, opponent_tiles
      clear_letters()
      update_counts()
      log_belongings()
      $(@).attr 'disabled', true
      delay 300, -> do_cheater_turn() unless game_over()
    else
      alert 'This word is not in the dictionary!'
      clear_letters()

  $('#done_action').on 'click', ->
    block_used_word suggested_answer['word']
    cheater_played_words.push suggested_answer['word']
    give_tiles suggested_answer['ids'], opponent_tiles, cheater_tiles
    clear_letters()
    update_counts()
    log_belongings()
    do_opponent_turn() unless game_over()

  $('#played_words_actions').on 'click', ->
    show_played_words()

  $('.input').click ->
    if not $(@).hasClass('called-letter') and $('.grid').hasClass('clickable')
      $(@).attr('data-letter-id', $('.called-letter').length + 1).addClass('called-letter')
      reposition_letters()

do_cheater_turn = ->
  $('#done_action').show()
  $('#clear_action, #submit_action').hide()
  $('p.status').html "Submit this word using these letters:"
  $('.grid').removeClass 'clickable'

  possible_answers = []
  find_arrangements(word) for word in possible_words

  possible_answers = _.sortBy possible_answers, (answer) -> answer['score']
  possible_answers = possible_answers.reverse()
  suggested_answer = possible_answers[0]
  display_answer suggested_answer

do_opponent_turn = ->
  $('#done_action').hide()
  $('#clear_action, #submit_action').show().attr 'disabled', false
  $('p.status').html "Click on letters that were used by your opponent in correct order"
  $('.grid').addClass 'clickable'

game_over = ->
  if cheater_tiles.length + opponent_tiles.length == 25
    alert "Game Over!"
    $('.grid').removeClass 'top-shifted'
    $('#done_action, #clear_action, #submit_action').hide()

show_played_words = ->
  if cheater_started
    first_words = cheater_played_words
    first_player = 'Cheater'
    second_words = opponent_played_words
    second_player = 'Opponent'
  else
    first_words = opponent_played_words
    first_player = 'Opponent'
    second_words = cheater_played_words
    second_player = 'Cheater'

  played_words = []
  repeat_times = first_words.length
  if repeat_times > 0
    for i in [0..(repeat_times - 1)]
      played_words.push { player: first_player, word: first_words[i] }
      played_words.push { player: second_player, word: second_words[i] } if second_words[i]
    alert ( "#{ played_word['word'] } (#{ played_word['player'] })\n" for played_word in played_words ).join('')
  else
    alert 'No word played'


is_possible = (word) ->
  word_letters = clone_array letters
  for i in [0..(word.length-1)]
    index = word_letters.indexOf word[i]
    if index isnt -1 then word_letters.splice index, 1 else return false
  true

indexes_for_letter = (letter) ->
  [indexes, removed, word_letters] = [ [], 0, clone_array(letters) ]
  while word_letters.indexOf(letter) isnt -1
    index = word_letters.indexOf letter
    indexes.push index + removed
    word_letters.splice index, 1
    removed += 1
  indexes

index_order_arrangements = (arrangements, indexes, limit) ->
  new_arrangements = []
  if arrangements.length is 0
    new_arrangements = ([index] for index in indexes)
  else
    return arrangements if arrangements[0].length == limit
    for arrangement in arrangements
      for index in indexes
        last_item_in_arrangement = arrangement[arrangement.length - 1]
        if index > last_item_in_arrangement
          new_index_array = clone_array arrangement
          new_index_array.push index
          new_arrangements.push new_index_array
  # recursion!
  index_order_arrangements new_arrangements, indexes, limit

create_index_lists = (letter_sections, current_combinations) ->
  if letter_sections.length > 0 then [ next_section, new_combinations ] = [ letter_sections.shift(), [] ] else return current_combinations
  if current_combinations.length is 0 then new_combinations = (combination for combination in next_section)
  else
    for combination in next_section
      for index_array in current_combinations
        new_index_array = clone_array index_array
        new_index_array.push index for index in combination
        new_combinations.push new_index_array
  # recursion!
  create_index_lists letter_sections, new_combinations

is_protected = ( belonging_indexes, index ) ->
  return false if (belonging_indexes.indexOf(index) is -1) or
    ( (index > 4) and (belonging_indexes.indexOf(index - 5) is -1) ) or
    ( (index < 20) and (belonging_indexes.indexOf(index + 5) is -1) ) or
    ( (index % 5 > 0) and (belonging_indexes.indexOf(index - 1) is -1) ) or
    ( (index % 5 < 4) and (belonging_indexes.indexOf(index + 1) is -1) )
  true

update_counts = ->
  $('#me_avatar .label').html cheater_tiles.length
  $('#opponent_avatar .label').html opponent_tiles.length

given_tiles = (new_ids, from_tiles, to_tiles) ->
  new_from_tiles = clone_array from_tiles
  new_to_tiles = clone_array to_tiles

  # see what opponent has protected - can't take that
  from_protected = ( id for id in new_ids when is_protected from_tiles, id )

  # remove from opponent
  for id in new_ids
    new_from_tiles.splice new_from_tiles.indexOf(id), 1 if new_from_tiles.indexOf(id) isnt -1 and from_protected.indexOf(id) is -1

  # give to me
  for id in new_ids
    new_to_tiles.push id if new_to_tiles.indexOf(id) is -1 and from_protected.indexOf(id) is -1

  [ new_from_tiles, new_to_tiles ]

board_letter_sections = (from_tiles, to_tiles) ->
  all_tiles = ( i for i in [0..24] )
  free_tiles = _.difference all_tiles, from_tiles, to_tiles
  from_protected = []
  from_protected = ( tile for tile in from_tiles when is_protected(from_tiles, tile))
  to_protected = []
  to_protected = ( tile for tile in to_tiles when is_protected to_tiles, tile )
  from_belonging = _.difference from_tiles, from_protected
  to_belonging = _.difference to_tiles, to_protected
  [ from_belonging, from_protected, to_belonging, to_protected, free_tiles ]

calculate_score = (ids) ->
  opponent_tiles_a = clone_array opponent_tiles
  cheater_tiles_a = clone_array cheater_tiles
  [ from_belonging_a, from_protected_a, to_belonging_a, to_protected_a, free_tiles_a ] = board_letter_sections opponent_tiles_a, cheater_tiles_a

  # l "From belonging (before)"
  # l from_belonging_a
  # l "From protected (before)"
  # l from_protected_a
  # l "To belonging (before)"
  # l to_belonging_a
  # l "To protected (before)"
  # l to_protected_a
  # l "Free (before)"
  # l free_tiles_a

  # play the words
  [ opponent_tiles_b, cheater_tiles_b ] = given_tiles ids, opponent_tiles_a, cheater_tiles_a
  [ from_belonging_b, from_protected_b, to_belonging_b, to_protected_b, free_tiles_b ] = board_letter_sections opponent_tiles_b, cheater_tiles_b

  # l "From belonging (after)"
  # l from_belonging_b
  # l "From protected (after)"
  # l from_protected_b
  # l "To belonging (after)"
  # l to_belonging_b
  # l "To protected (after)"
  # l to_protected_b
  # l "Free (after)"
  # l free_tiles_b

  ###
    Calculate score
    For every new id, check what kind of id it was, and is now.

    If it was protected by enemy - 0
    If it belonged to me or was protected by me - 0
    If it belonged to enemy - 2
    If it was free - 1
    If we gain protected tile +2
  ###

  score = 0
  for id in ids
    score += 2 if from_belonging_a.indexOf(id) isnt -1
    score += 1 if free_tiles_a.indexOf(id) isnt -1
  score += ( to_protected_b.length - to_protected_a.length ) * 2
  score

find_arrangements = (word) ->
  word_letter_counts = {}
  board_letter_counts = {}

  for i in [0..24]
    if board_letter_counts.hasOwnProperty(letters[i]) then board_letter_counts[letters[i]] += 1 else board_letter_counts[letters[i]] = 1
  for i in [0..(word.length-1)]
    if word_letter_counts.hasOwnProperty(word[i]) then word_letter_counts[word[i]] += 1 else word_letter_counts[word[i]] = 1

  word_letter_arrangements = []
  for letter, word_letter_count of word_letter_counts
    letter_indexes = indexes_for_letter letter
    if board_letter_counts[letter] > word_letter_count
      index_arrangements = index_order_arrangements([], (i for i in [0..(board_letter_counts[letter]-1)]), word_letter_count)
      letter_arrangements =  ( (letter_indexes[index] for index in arrangement) for arrangement in index_arrangements )
    else
      letter_arrangements = [ letter_indexes ]
    word_letter_arrangements.push letter_arrangements

  possible_combinations = create_index_lists word_letter_arrangements, []

  for possible_combination in possible_combinations
    possible_answers.push
      word: word
      ids: possible_combination
      score: calculate_score possible_combination

display_answer = (answer) ->
  new_ids = clone_array answer['ids']
  for i in [0..(answer['word'].length-1)]
    for id in new_ids
      if letters[id] is answer['word'][i]
        $("#input_#{ id }").attr('data-letter-id', $('.called-letter').length + 1).addClass 'called-letter'
        new_ids.splice new_ids.indexOf(id), 1
        break
  reposition_letters()

clear_letters = ->
  $('.called-letter').each -> $(@).removeAttr('data-letter-id style').removeClass('called-letter')

block_used_word = (given_word) ->
  if possible_words.indexOf(given_word) == -1 then return false
  else
    removable_words = ( i for i in [0..(possible_words.length - 1)] when possible_words[i].substring(0, given_word.length) == given_word )
    possible_words.splice(i, 1) for i in removable_words.sort (a, b) -> b - a
    true

give_tiles = (new_ids, from_tiles, to_tiles) ->
  # see what opponent has protected - can't take that
  protected_ids = ( id for id in new_ids when is_protected(from_tiles, id) )
  # remove from opponent
  for id in new_ids
    from_tiles.splice from_tiles.indexOf(id), 1 if from_tiles.indexOf(id) isnt -1 and protected_ids.indexOf(id) is -1
  # give to me
  for id in new_ids
    to_tiles.push id if to_tiles.indexOf(id) is -1 and protected_ids.indexOf(id) is -1
  # recalculate protections
  $('.row .input').removeClass 'belonging_own protected_own belonging_opponent protected_opponent'
  for index in cheater_tiles
    $("#input_#{ index }").addClass 'belonging_own'
    $("#input_#{ index }").addClass 'protected_own' if is_protected cheater_tiles, index
  for index in opponent_tiles
    $("#input_#{ index }").addClass 'belonging_opponent'
    $("#input_#{ index }").addClass 'protected_opponent' if is_protected opponent_tiles, index

reposition_letters = ->
  letter_count = $('.called-letter').length
  $('.called-letter').each -> $(@).css { top: "20px", left: "#{ (375 - (letter_count * 75)) / 2 + (($(@).attr('data-letter-id') - 1) * 75) }px" }

'use strict'

angular.module('sc2App').directive 'player', (audioContext, HelperService, CanvasService, ContentService, SoundCloudService, animation, $filter) ->
    {
        restrict: 'A'
        link: (scope, element, attrs) ->
            player = audioContext.player
            scope.playerData = {}
            scope.fsScope = false

            onTimeupdate = ->
                scope.$apply ->
                    scope.playerData.currentTime = player.currentTime
                    scope.playerData.currentTimeFormatted = HelperService.duration(player.currentTime * 1000)

            onEnded = ->
                scope.$apply ->
                    scope.playerData.currentTrack.isPlaying = false
                    if scope.settings.autoAdvance and ContentService.player.nextTrack
                        scope.playerData.playingIndex = ContentService.player.nextTrack.index
                        ContentService.player.previousTrack = ContentService.player.currentTrack
                        ContentService.player.currentTrack = ContentService.player.nextTrack
                        ContentService.player.currentTrack.isPlaying = true
                        scope.$emit 'playTrack'

                    else
                        scope.playerData.playingIndex = null
                        scope.playerData.currentTime = 0
                        animation.killAnimation()

            onCanplay = ->
                scope.$apply ->
                    scope.playerData.duration = player.duration
                    scope.playerData.seeking = false

            onSeeking = ->
                scope.$apply ->
                    scope.playerData.seeking = true

            onSeeked = ->
                scope.$apply ->
                    scope.playerData.seeking = false

            onProgress = ->
                ranges = []
                for range in player.buffered
                    ranges.push [
                        player.buffered.start(range)
                        player.buffered.end(range)
                    ]

                if ranges.length
                    scope.$apply ->
                        scope.playerData.buffered = ranges[ranges.length - 1][1]

            setEventListeners = ->
                player.addEventListener 'timeupdate', onTimeupdate, false
                player.addEventListener 'canplay', onCanplay, false
                player.addEventListener 'seeking', onSeeking, false
                player.addEventListener 'seeked', onSeeked, false
                player.addEventListener 'progress', onProgress, false
                player.addEventListener 'ended', onEnded, false

            play = ->
                scope.playerData.currentTrack.isPlaying = true
                player.play()
                if !animation.requestId
                    animation.animate()

            pause = ->

                player.pause()
                animation.killAnimation()

            getNext = ->
                filtered = $filter('filter')(ContentService.content.stream, scope.streamFilter)
                found = false
                for track in filtered
                    if found
                        if track.hasOwnProperty 'tracks'
                            ContentService.player.nextTrack = track.tracks[0]
                        else
                            ContentService.player.nextTrack = track
                        break

                    if track.index[0] == ContentService.player.currentTrack.index[0]
                        if track.hasOwnProperty 'tracks'
                            if track.index[1] == ContentService.player.currentTrack.index[1]
                                found = true
                        else
                            found = true
                        # if track.index[1] == data.current.index[1]
                        #     console.log 'playlist'
                        #     # found = true

            scope.$on 'playTrack', (evt) ->
                getNext()

                if ContentService.player.previousTrack and angular.equals ContentService.player.currentTrack.index, ContentService.player.previousTrack.index
                    play()
                else
                    if ContentService.player.previousTrack
                        pause()
                        ContentService.player.previousTrack.isPlaying = false
                    SoundCloudService.getProperStreamUrl(ContentService.player.currentTrack.scid).then (response) ->

                        if response.url
                            if !response.vis
                                player = audioContext.playerNoVis
                                scope.status.access = 'Limited access to track, visualizers disabled'
                            else
                                player = audioContext.player
                                scope.status.access = false

                            setEventListeners()
                            scope.playerData.currentTrack = ContentService.player.currentTrack
                            scope.playerData.vis = response.vis
                            player.src = response.url
                            play()
                        else
                            scope.status.access = 'No playable stream exists'
                            scope.playerData.currentTrack = undefined
                            player.src = ''
                            pause()

                    SoundCloudService.getWaveformData(ContentService.player.currentTrack.waveform).then (response) ->
                        # make it 1
                        CanvasService.drawWaveform response.data.samples, CanvasService.canvases().waveformContext, 'rgba(255,255,255,0.05)'
                        CanvasService.drawWaveform response.data.samples, CanvasService.canvases().waveformBufferContext, 'rgba(255,255,255,0.15)'
                        CanvasService.drawWaveform response.data.samples, CanvasService.canvases().waveformProgressContext, '#ffffff'

            scope.$on 'pauseTrack', ->
                scope.playerData.currentTrack.isPlaying = false
                pause()

            scope.$on 'seekTrack', (evt, data) ->
                player.currentTime = (data * player.duration).toFixed()

            scope.$on 'seekPreview', (evt, data) ->
                scope.seekCursor =
                    xpos: data.xpos
                    time: HelperService.duration(data.xpos * player.duration * 1000 / data.width)

            scope.helpers =
                setVolume: (value) ->
                    audioContext.gain.value = value * value / 10000
                toggleOsc: (bool) ->
                    if !scope.status.access and scope.playerData.playingIndex and bool
                        scope.fsScope = animation.x3dscope = true
                    else
                        scope.fsScope = animation.x3dscope = false
    }

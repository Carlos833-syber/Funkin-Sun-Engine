package funkin.ui.debug;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

import funkin.ui.MusicBeatSubState;
import funkin.ui.FullScreenScaleMode;
import funkin.audio.FunkinSound;
import funkin.ui.TextMenuList;
import funkin.ui.debug.charting.ChartEditorState;
import funkin.util.logging.CrashHandler;
import funkin.util.FileUtil;

import flixel.addons.transition.FlxTransitionableState;

#if mobile
import funkin.mobile.input.ControlsHandler;
import funkin.util.TouchUtil;
import funkin.util.SwipeUtil;
import funkin.util.HapticUtil;
#end

class DebugMenuSubState extends MusicBeatSubState
{
  var items:TextMenuList;
  var camFocusPoint:FlxObject;

  #if mobile
  var mobileHint:FlxText = null;
  #end

  override function create():Void
  {
    FlxTransitionableState.skipNextTransIn = true;

    super.create();

    bgColor = 0x00000000;

    // Camera focus point.
    camFocusPoint = new FlxObject(0, 0);
    add(camFocusPoint);

    FlxG.camera.follow(camFocusPoint, null, 0.06);

    // Debug menu background.
    var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));

    menuBG.color = 0xFF4CAF50;

    menuBG.setGraphicSize(
      Std.int(
        menuBG.width
        * 1.1
        * FullScreenScaleMode.wideScale.x
      )
    );

    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);

    add(menuBG);

    // Menu list.
    items = new TextMenuList();
    items.onChange.add(onMenuChange);

    add(items);

    /*
     * DEBUG MENU OPTIONS
     */

    #if FEATURE_CHART_EDITOR
    createItem(
      "CHART EDITOR",
      openChartEditor
    );
    #end

    #if FEATURE_ANIMATION_EDITOR
    createItem(
      "ANIMATION EDITOR",
      openAnimationEditor
    );
    #end

    #if FEATURE_STAGE_EDITOR
    createItem(
      "STAGE EDITOR",
      openStageEditor
    );
    #end

    #if FEATURE_RESULTS_DEBUG
    createItem(
      "RESULTS SCREEN DEBUG",
      openTestResultsScreen
    );
    #end

    #if sys
    createItem(
      "OPEN CRASH LOG FOLDER",
      openLogFolder
    );
    #end

    /*
     * Prevent a crash if no debug options exist.
     */
    if (items.members.length > 0)
    {
      onMenuChange(items.members[0]);

      FlxG.camera.focusOn(
        new FlxPoint(
          camFocusPoint.x,
          camFocusPoint.y + 500
        )
      );
    }

    #if FEATURE_HAXEUI
    haxe.ui.Toolkit.styleSheet.clear("user");
    #end

    #if mobile

    /*
     * Android/mobile back button.
     */
    addBackButton(
      FlxG.width - 230,
      FlxG.height - 200,
      FlxColor.WHITE,
      exitDebugMenu,
      1.0
    );

    if (backButton != null)
    {
      backButton.onConfirmStart.add(() ->
      {
        FunkinSound.playOnce(
          Paths.sound('cancelMenu')
        );
      });
    }

    /*
     * Mobile instruction.
     */
    mobileHint = new FlxText(
      0,
      FlxG.height - 40,
      FlxG.width,
      'Tap an option to select it - swipe down to go back',
      16
    );

    mobileHint.alignment = CENTER;
    mobileHint.color = 0xFFAAAAAA;
    mobileHint.scrollFactor.set(0, 0);

    add(mobileHint);

    #end
  }

  /**
   * Moves the camera to the currently selected menu item.
   */
  function onMenuChange(selected:Dynamic):Void
  {
    if (selected == null)
    {
      return;
    }

    camFocusPoint.setPosition(
      selected.x + selected.width / 2,
      selected.y + selected.height / 2
    );
  }

  override function update(elapsed:Float):Void
  {
    try
    {
      updateDebugMenu(elapsed);
    }
    catch (e)
    {
      FlxG.log.error(
        'DebugMenuSubState encountered an error and had to close: $e'
      );

      exitDebugMenu();
    }
  }

  function updateDebugMenu(elapsed:Float):Void
  {
    super.update(elapsed);

    #if mobile

    if (backButton != null)
    {
      backButton.active = true;
      backButton.enabled = true;
    }

    handleTouchInput();

    #end

    if (controls.BACK_P)
    {
      FunkinSound.playOnce(
        Paths.sound('cancelMenu')
      );

      exitDebugMenu();
    }
  }

  #if mobile

  /**
   * Handles Android touch input.
   *
   * TextMenuList already handles the menu item
   * callbacks, so we do not need a separate
   * touchableItems array here.
   */
  function handleTouchInput():Void
  {
    if (
      SwipeUtil.swipeDown
      && !ControlsHandler.usingExternalInputDevice
    )
    {
      FunkinSound.playOnce(
        Paths.sound('cancelMenu')
      );

      exitDebugMenu();

      return;
    }

    /*
     * Touch selection.
     *
     * TextMenuList handles its own item activation.
     * We only provide a small visual/haptic response
     * when the player touches the screen.
     */
    if (
      TouchUtil.justPressed
      && !ControlsHandler.usingExternalInputDevice
    )
    {
      HapticUtil.vibrate(
        0,
        0.01,
        0.5
      );
    }
  }

  #end

  /**
   * Creates a debug menu item.
   */
  function createItem(
    name:String,
    callback:Void->Void,
    fireInstantly:Bool = false
  ):Dynamic
  {
    var item = items.createItem(
      0,
      100 + items.length * 100,
      name,
      BOLD,
      callback
    );

    item.fireInstantly = fireInstantly;

    item.screenCenter(X);

    return item;
  }

  #if FEATURE_CHART_EDITOR

  function openChartEditor():Void
  {
    FlxTransitionableState.skipNextTransIn = true;

    FlxG.switchState(
      () -> new ChartEditorState()
    );
  }

  #end

  #if FEATURE_ANIMATION_EDITOR

  function openAnimationEditor():Void
  {
    FlxTransitionableState.skipNextTransIn = true;

    FlxG.switchState(
      () -> new funkin.ui.debug.anim.DebugBoundingState()
    );
  }

  #end

  #if FEATURE_STAGE_EDITOR

  function openStageEditor():Void
  {
    FlxTransitionableState.skipNextTransIn = true;

    FlxG.switchState(
      () -> new funkin.ui.debug.stageeditor.StageEditorState()
    );
  }

  #end

  #if FEATURE_RESULTS_DEBUG

  function openTestResultsScreen():Void
  {
    FlxTransitionableState.skipNextTransIn = true;

    FlxG.switchState(
      () -> new funkin.ui.debug.results.ResultsDebugSubState()
    );
  }

  #end

  #if sys

  function openLogFolder():Void
  {
    FileUtil.openFolder(
      CrashHandler.LOG_FOLDER
    );
  }

  #end

  function exitDebugMenu():Void
  {
    FlxTransitionableState.skipNextTransIn = true;

    this.close();
  }

  override public function destroy():Void
  {
    #if mobile

    if (mobileHint != null)
    {
      mobileHint.destroy();
      mobileHint = null;
    }

    #end

    super.destroy();
  }
}

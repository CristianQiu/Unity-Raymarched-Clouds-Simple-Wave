using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/// <summary>
/// This script provides a free fly camera behaviour designed for K&M
/// </summary>
public class FreeCam : MonoBehaviour
{
    #region Public Attributes

    public float movSpeed = 2.0f;
    public float rotSpeed = 270.0f;

    public float movSpeedSprintMod = 2.5f;

    #endregion

    #region Private Attributes



    #endregion

    #region Properties



    #endregion

    #region MonoBehaviour Methods

    // Use this for initialization
    private void Start () 
    {
        
    }
	
    // Update is called once per frame
    private void Update () 
    {
        float dt = Time.unscaledDeltaTime;

        MouseRotateView(dt);
        Move(dt);
        MoveAlongWorldUp(dt);
    }

    #endregion

    #region Methods

    /// <summary>
    /// Rotate the view with the mouse
    /// </summary>
    /// <param name="dt"></param>
    private void MouseRotateView(float dt)
    {
        // skip the rotation if the right mouse button is not clicked
        if (!Input.GetMouseButton(1))
            return;

        float x = Input.GetAxisRaw("Mouse X");
        float y = Input.GetAxisRaw("Mouse Y");

        // rotate around the world up and the local X axis
        Quaternion yRotationOffset = Quaternion.AngleAxis(x * rotSpeed * dt, Vector3.up);
        Quaternion xRotationOffset = Quaternion.AngleAxis(-y * rotSpeed * dt, transform.right);

        // update the rotation
        transform.rotation = yRotationOffset * xRotationOffset * transform.rotation;
    }

    /// <summary>
    /// Move the camera freely
    /// </summary>
    /// <param name="dt"></param>
    private void Move(float dt)
    {
        float y = Input.GetAxisRaw("Vertical");
        float x = Input.GetAxisRaw("Horizontal");

        // get the dir and normalize it
        Vector3 movDir = new Vector3(x, 0.0f, y);
        movDir.Normalize();

        // check to sprint witht the left shift
        float speed = Input.GetKey(KeyCode.LeftShift) ? movSpeed * movSpeedSprintMod : movSpeed;

        // update the position
        Vector3 finalMovement = (transform.forward * movDir.z * speed * dt) + (transform.right * movDir.x * speed * dt);
        transform.position += finalMovement;
    }

    /// <summary>
    /// Move along the world Y axis with the left control and the left alt
    /// </summary>
    /// <param name="dt"></param>
    private void MoveAlongWorldUp(float dt)
    {
        // check wether we want to go up or down
        bool up = Input.GetKey(KeyCode.LeftControl);
        bool down = Input.GetKey(KeyCode.LeftAlt);

        float speed = 0.0f;

        if (up && !down)
            speed = movSpeed;
        else if (down && !up)
            speed = -movSpeed;

        // update the position
        Vector3 movement = Vector3.up * speed * dt;
        transform.position += movement;
    }

    #endregion
}
